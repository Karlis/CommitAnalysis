package myheadlessplugin;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;



import myfirstplugin.PPATypeVisitor;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.eclipse.jdt.core.dom.CompilationUnit;
import org.eclipse.swt.widgets.Display;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.PlatformUI;

import ca.mcgill.cs.swevo.ppa.PPAOptions;
import ca.mcgill.cs.swevo.ppa.util.PPACoreUtil;


import com.eclipsesource.json.JsonObject;
import com.eclipsesource.json.JsonObject.Member;




/**
 * This class controls all aspects of the application's execution
 */
public class Application implements IApplication {
	
	public String readFile(String filename)
	{
	   String content = null;
	   File file = new File(filename); //for ex foo.txt
	   try {
	       FileReader reader = new FileReader(file);
	       char[] chars = new char[(int) file.length()];
	       reader.read(chars);
	       content = new String(chars);
	       reader.close();
	   } catch (IOException e) {
	       e.printStackTrace();
	   }
	   return content;
	}
	
	public String getGraph(String[] commitFiles, PPATypeVisitor visitor, ByteArrayOutputStream baos, String projectDir, String tmpFileNameDir){
		
		String commit_files_string = "";
		
		for( String filename : commitFiles ) {
			String tmpFileName = tmpFileNameDir + filename;
			File commit_file = new File(projectDir + "/" + filename);
			
			
			String extension = "";
			int i = filename.lastIndexOf('.');
			if (i >= 0) { extension = filename.substring(i+1); }
			
			if (commit_file.isFile() && extension.equalsIgnoreCase("java") && (commit_file.length() / 1024) < 250 ){ //only files that are less than huge
				System.out.print(".");
				// before check if file is already in "cahce"
				if ( new File (tmpFileName).isFile()){ // It's ok.
				} else {
					CompilationUnit cu = PPACoreUtil.getCU(commit_file, new PPAOptions());
				    cu.accept(visitor);
				    try{
				    	writeFile(tmpFileName, baos.toString());
				    	baos.reset();
				    }
				    catch (Exception e) {
				    	e.printStackTrace();
				    }
				}
				
				try {
                commit_files_string = commit_files_string + parseGraph( readFile( tmpFileName ) );
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
		return commit_files_string;
	}
	
	public void writeFile(String filename, String content) {
			File file = new File(filename);
		try{
			if (!file.exists()) {
				file.getParentFile().mkdirs();
				file.createNewFile();
			}
 
			FileWriter fw = new FileWriter(file.getAbsoluteFile());
			BufferedWriter bw = new BufferedWriter(fw);
			bw.write(content);
			bw.close();	
 
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public String[] getCommitList(String projectDir, String commitOld, String commitNew){
        // what changes (commits) are made from old to new
        String cmdString = new String("git log " + commitOld + ".." + commitNew + " --oneline --first-parent");
        String[] commitList = cmdExec(cmdString, projectDir).split(new String("\n"));
        return commitList;
    };
	
	
	public String[] getFilenameList(String projectDir, String commitHashX, String commitHashY, String module){
		
		String cmdString = new String("git diff --name-only " + commitHashX + " " + commitHashY + " " + module);
		String x = cmdExec(cmdString, projectDir);
		String[] filenameList = x.split(new String("\n"));
		List<String> javaFiles = new ArrayList<String>();
		
		
		// Select only .java files
		for (String filename : filenameList){
			String extension = "";
			int i = filename.lastIndexOf('.');
			if (i >= 0) { extension = filename.substring(i+1); }
			
			if (extension.equalsIgnoreCase("java")){
				javaFiles.add(filename);
			}
		}
		String[] returnArray = new String[ javaFiles.size() ];
		javaFiles.toArray(returnArray);
		
		
		System.out.print("Got: ");
		System.out.print(returnArray.length);
		System.out.println(" files changed in " + commitHashX + " .. " + commitHashY);
		return returnArray;
	};
	
	public void gitCheckoutCommit(String commit_hash, String project_dir){		
		try {
			
			Runtime.getRuntime().exec(new String("git checkout " + commit_hash),null, new File(project_dir));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public static String cmdExec(String cmdLine, String dir) {
	    String line;
	    String output = "";
	    try {
	        Process p = Runtime.getRuntime().exec(cmdLine, null, new File(dir));
	        BufferedReader input = new BufferedReader
	            (new InputStreamReader(p.getInputStream()));
	        while ((line = input.readLine()) != null) {
	            output += (line + '\n');
	        }
	        input.close();
	        }
	    catch (Exception ex) {
	        ex.printStackTrace();
	    }
	    return output;
	}
	
	public void deleteTmpFiles() {
		// TODO: CHANGE TO MY COMPUTER OR PUT IN SETTINGS 
        cmdExec("rm /Users/klukstins/Documents/workspace/.metadata/.plugins/org.eclipse.core.resources/.projects/__PPA_PROJECT0/markers*","/");
    };
    
    public static String parseGraph(String graphString){
    	// Do parsing like it was done in ruby
    	String[] lines = graphString.split(System.getProperty("line.separator"));
    	
    	String parsedGraph = "";
    	
    	String currentClass = "";
    	Boolean classOpen = false;
    	for (String line : lines)	{
			if ( line.contains(new String("--binding") )){

				line = line.replace("--binding ","");
				
				String[] lineStringArray = line.split(new String(" --link "));
				String classLinked = lineStringArray[0];
				String linkToClass = lineStringArray[1];
		
    			if (classOpen){    				
    				parsedGraph = parsedGraph.concat( currentClass + ", " + classLinked + ", " + linkToClass + "\n"  );
        		} else {
        			currentClass = classLinked.replace("--class ","");;
        		}
    		}	
    		if ( line.contains(new String("--class") )){
    			classOpen = true;
    		} else if ( line.contains(new String("--end") )){
    			classOpen = false;
    		}	
    	}
    	return parsedGraph;
    }
    
	
    public Object start(IApplicationContext context) throws Exception {
        String[] args = (String[]) context.getArguments().get(
                IApplicationContext.APPLICATION_ARGS);

        if (args.length < 2){
            System.out.println("No filename supplied. Add '-file path_to_file_name.java'");
            return IApplication.EXIT_OK;
        }

        try{

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PrintStream ps_to_string = new PrintStream(baos);
            PPATypeVisitor visitor = new PPATypeVisitor(ps_to_string);

            // Take each project and for each commit get the file list before calculating the similarity
            String fileContents = readFile(args[1]);
            JsonObject projectsJson =JsonObject.readFrom( fileContents );

            for (Member project: projectsJson){
            	
            	
            	
                String projectDir = project.getValue().asObject().get("project_dir").asString();
                String module = project.getValue().asObject().get("module").asString();
                
                String commitHashAlfa = project.getValue().asObject().get("alfa_hash").asString();
                String commitHashOmega = project.getValue().asObject().get("omega_hash").asString();
                
                String commitEnd = project.getValue().asObject().get("alfa_hash").asString();
                String commitX = project.getValue().asObject().get("omega_hash").asString();
                
//                String commitEnd = project.getValue().asObject().get("current_end").asString();
//                String commitX = project.getValue().asObject().get("current_x").asString();

                String alfaCommitFileStructure = "/Users/klukstins/dev/University/thesis/tmpParsed/A/";
                String omegaCommitFileStructure = "/Users/klukstins/dev/University/thesis/tmpParsed/O/";
                String currentCommitFileStructure = "/Users/klukstins/dev/University/thesis/tmpParsed/C/";
                
                // Get list of all commits hashes between alfa and omega
                String[] commitList = getCommitList(projectDir, commitEnd, commitX);
                String prevCommit = commitHashOmega;

                System.out.print("Total number of commits: ");
                System.out.println(commitList.length);
                
                String alfa_files_string = "";
                String alfa_x_files_string = "";
                String omega_x_files_string = "";
                String omega_files_string = "";

                for (String commit : commitList){
                    // Optimize by sending alfa and omega files to PPA only once
                    // By keeping a copy of PPA result of each commit and re-send to PPA only the files that have
                    // changed between the next commit and saved copy.

                    commit = commit.split(new String(" ") )[0];
                    System.out.println(commit);

                    // Get filenames from diff with current commit
                    String[] diffPreviousFilenames = getFilenameList(projectDir, prevCommit, commit, module);
                    prevCommit = commit;

                    if (diffPreviousFilenames.length > 0){
                    	// Change values if there is difference
                    	String[] diffAlfaFilenames = getFilenameList(projectDir, commitHashAlfa, commit, module);
                        String[] diffOmegaFilenames = getFilenameList(projectDir, commit, commitHashOmega, module);
                    	
	                    // checkout Alfa
	                    cmdExec("git checkout " + commitHashAlfa, projectDir);
	                    alfa_files_string = getGraph(diffAlfaFilenames, visitor, baos, projectDir, alfaCommitFileStructure);
	                    System.out.println("A");
	                    
	                    //Checkout CurrentCommit
	                    cmdExec("git checkout " + commit, projectDir);
	                    // Clear cache of all files that have been changed in the last commit
	                    for (String previousFilename : diffPreviousFilenames){
	                    	new File(currentCommitFileStructure + previousFilename).delete();
	                    }
	                    alfa_x_files_string = getGraph(diffAlfaFilenames, visitor, baos, projectDir, currentCommitFileStructure);
	                    omega_x_files_string = getGraph(diffOmegaFilenames, visitor, baos, projectDir, currentCommitFileStructure);
	                    System.out.println("C");
	                    
	                    //checkout Omega
	                    cmdExec("git checkout " + commitHashOmega, projectDir);
	                    omega_files_string = getGraph(diffOmegaFilenames, visitor, baos, projectDir, omegaCommitFileStructure);
	                    System.out.println("O");
	                

	                    // Finalize
	                    JsonObject outCommitObj = new JsonObject()
	                        .add( "commit", commit )
	                        .add( "alfa", alfa_files_string )
	                        .add( "alfa_x", alfa_x_files_string )
	                        .add( "omega_x", omega_x_files_string )
	                        .add( "omega", omega_files_string );
	
	                    // Save all data
	                    PrintStream print_to_file = new PrintStream(new File(new String("/Users/klukstins/dev/University/thesis/thesis_output.txt")));
	                    print_to_file.print(outCommitObj.toString());
	                    print_to_file.flush();
	                    deleteTmpFiles();
	
	                    // Parse commit data
	                    System.out.println(cmdExec("ruby /Users/klukstins/dev/University/thesis/bitbucket/scripts/parse_ppa.rb /Users/klukstins/dev/University/thesis/thesis_output.txt", "/Users/klukstins/dev/University/thesis/") );
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        System.out.println("DONE");
        return IApplication.EXIT_OK;
    }

	/* (non-Javadoc)
	 * @see org.eclipse.equinox.app.IApplication#stop()
	 */
	public void stop() {
		if (!PlatformUI.isWorkbenchRunning())
			return;
		final IWorkbench workbench = PlatformUI.getWorkbench();
		final Display display = workbench.getDisplay();
		display.syncExec(new Runnable() {
			public void run() {
				if (!display.isDisposed())
					workbench.close();
			}
		});
	}
}
