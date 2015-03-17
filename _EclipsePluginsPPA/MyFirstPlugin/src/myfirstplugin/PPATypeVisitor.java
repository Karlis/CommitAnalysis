package myfirstplugin;

import java.io.PrintStream;

import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.jdt.core.dom.ASTNode;
import org.eclipse.jdt.core.dom.ASTVisitor;
import org.eclipse.jdt.core.dom.ClassInstanceCreation;
import org.eclipse.jdt.core.dom.Expression;
import org.eclipse.jdt.core.dom.IBinding;
import org.eclipse.jdt.core.dom.ITypeBinding;
import org.eclipse.jdt.core.dom.MethodInvocation;
import org.eclipse.jdt.core.dom.Name;
import org.eclipse.jdt.core.dom.PPABindingsUtil;
import org.eclipse.jdt.core.dom.TypeDeclaration;

public class PPATypeVisitor extends ASTVisitor {

	private PrintStream printer;
	
	public PPATypeVisitor(PrintStream printer) {
		super();
		this.printer = printer;
	}
	
	@Override
	public boolean visit(TypeDeclaration node){
		printer.print("--class ");
		return true;
	}
	
	@Override
	public void endVisit(TypeDeclaration node){
		printer.println("--end");
	}

	@Override
	public void postVisit(ASTNode node) {
		super.postVisit(node);	

		if (node instanceof Expression) {
			Expression exp = (Expression) node;

//			IBinding binding = null;
			if (exp instanceof Name) {
				
				Name name = (Name) exp;
//				System.out.println( new String ("AAAAA"));
//				System.out.println( name.toString());
//				binding = name.resolveBinding();
//			} else if (exp instanceof MethodInvocation) {
//				MethodInvocation mi = (MethodInvocation) exp;
//				binding = mi.resolveMethodBinding();
//			} else if (exp instanceof ClassInstanceCreation) {
//				ClassInstanceCreation cic = (ClassInstanceCreation) exp;
//				binding = cic.resolveConstructorBinding();
			} else {
				return;
			}
			
			ITypeBinding tBinding = exp.resolveTypeBinding();
			
			if (tBinding != null) {
				printer.print("--binding ");
				printer.print(tBinding.getQualifiedName());
			}
			printer.println(" --link " + node.toString());

//			if (binding != null) {
//				printer.println("  " + PPABindingsUtil.getBindingText(binding));
//			}
			printer.flush();
		}
	}

}
