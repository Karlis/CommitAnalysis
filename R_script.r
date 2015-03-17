####################################################################################################
# EVERYTHING ABOUT A PROJECT I WOULD WANT TO KNOW
####################################################################################################
require(data.table)
# tables = c("spring", "elasticsearch")
tables = c("junit", "storm","eclipse", "spring", "elasticsearch")
for (table in tables){

    # General project stats:
    print("------------")
    print( table)
    print("------------")


    myTable = data.table( read.csv( paste("data/",table,"/data_table.csv", sep="") ))
    myPrecedenceTable = data.table( read.csv( paste("data/",table,"/Preceeding.csv", sep="") ))
    bugs = myTable[type %like% "bug"]
    bugsWithJumpsInHistory = bugs[arch_pn>0 | churn_pn >0 ]
    nonBugs = myTable[!type %like% "bug"]
    churn = myTable[type %like% "churn"]
    arch = myTable[type %like% "arch"]
    bothjumps = churn[type %like% "arch"]
    jumps = myTable[type %like% "arch" | type %like% "churn"]
    total = length(myTable$type)
    induce = myTable[type %like% "induce"]



# How many bugs are linked by churn and how many are not. -----------------------------------------
    # nchurn = myTable[!type %like% "churn"]
    # print("Churn Average links:")
    # print(mean(churn$nodes_n))
    # print("NonChurn Average links:")
    # print(mean(nchurn$nodes_n))



    # SHARED JUMPS ---------------------------------------------------------------------------------
    print ("In 1-step")
    sharedJumps = data.table(StepOne= jumps$bugs_n_1, StepTwo = jumps$bugs_n)[StepOne >0]
    print( paste(" Jumps are on average shared by X bugs:", mean(sharedJumps$StepOne)) )
    sharedJumps = data.table(StepOne= arch$bugs_n_1, StepTwo = arch$bugs_n)[StepOne >0]
    print( paste(" Arch Jumps are on average shared by X bugs:", mean(sharedJumps$StepOne)) )
    sharedJumps = data.table(StepOne= churn$bugs_n_1, StepTwo = churn$bugs_n)[StepOne >0]
    print( paste(" Churn Jumps are on average shared by X bugs:", mean(sharedJumps$StepOne)) )

    print ("In 2-step")
    sharedJumps = data.table(StepOne= jumps$bugs_n_1, StepTwo = jumps$bugs_n)[StepOne >0 | StepTwo >0 ]
    print( paste(" Jumps are on average shared by X bugs:", mean(sharedJumps$StepTwo)) )
    sharedJumps = data.table(StepOne= arch$bugs_n_1, StepTwo = arch$bugs_n)[StepOne >0 | StepTwo >0 ]
    print( paste(" Arch Jumps are on average shared by X bugs:", mean(sharedJumps$StepTwo)) )
    sharedJumps = data.table(StepOne= churn$bugs_n_1, StepTwo = churn$bugs_n)[StepOne >0 | StepTwo >0 ]
    print( paste(" Churn Jumps are on average shared by X bugs:", mean(sharedJumps$StepTwo)) )

# SHARED JUMPS --------------------------------------------------------------------------------- END

# Number of jump commits ---------------------------------------------------------------------------
    commitsWithBugsInFuture = myTable[bugs_n > 0]
    numArchHistoryOfBugFix = commitsWithBugsInFuture[type %like% "arch" ]
    numChurnHistoryOfBugFix = commitsWithBugsInFuture[type %like% "churn"]
    numJumpHistoryOfBugFix = commitsWithBugsInFuture[type %like% "churn" | type %like% "arch"]
    numInduceHistoryOfBugFix = commitsWithBugsInFuture[type %like% "induce" ]

    print ("----------------------------------------------")
    print ("Number of commits are located in histories of bug fixing commits:")
    print( paste("Large Changes:", length(numJumpHistoryOfBugFix$type)  ) )
    print( paste("Large Churn:", length(numChurnHistoryOfBugFix$type)  ) )
    print( paste("Large Architecture Change:", length(numArchHistoryOfBugFix$type)  ) )
    print( paste("Bug Inducing:", length(numInduceHistoryOfBugFix$type)  ) )
    print ("----------------------------------------------")
    print ("Number of commits are located in histories of bug fixing commits AND induce bugs:")
    print( paste("Large Changes:", length(numJumpHistoryOfBugFix[type %like% "induce"]$type)  ) )
    print( paste("Large Churn:", length(numChurnHistoryOfBugFix[type %like% "induce"]$type)  ) )
    print( paste("Large Architecture Change:", length(numArchHistoryOfBugFix[type %like% "induce"]$type)  ) )
    print ("----------------------------------------------")


# Number of jump commits ----------------------------------------------------------------------- END



    # How many have Arch -> Churn -> Bug
    pressBugs = myPrecedenceTable[Type %like% "bug"]
    pressBugsCA = pressBugs[CA > 0]
    pressBugsAC = pressBugs[AC > 0]
    print( paste("How many of the bugs have Churn jump following an Arch jump:", length( pressBugsCA$Type ) ) )
    print( paste("How many of the bugs have Arch jump following an Churn jump:", length( pressBugsAC$Type ) ) )


    pressBugs = myPrecedenceTable[!Type %like% "bug"]
    pressBugsCA = pressBugs[CA > 0]
    pressBugsAC = pressBugs[AC > 0]
    print( paste("How many of the !bugs have Churn jump following an Arch jump:", length( pressBugsCA$Type ) ) )
    print( paste("How many of the !bugs have Arch jump following an Churn jump:", length( pressBugsAC$Type ) ) )


    # How many churn is followed by architecture
    churn = myTable[type %like% "churn"]

    print( paste( "How many A->C: ", length(churn[ arch_p_1 > 0 ]$type) ))
    print( paste( "How many A->C->B: ", length(churn[ arch_p_1 > 0 & bugs_n_1 > 0 ]$type) ))
    # how many architecture is followed by churn

    arch = myTable[type %like% "arch"]
    print( paste( "How many C->A: ", length(arch[ churn_p_1 > 0 ]$type) ))
    print( paste( "How many C->A->B: ", length(arch[ churn_p_1 > 0 & bugs_n_1 > 0 ]$type) ))


    print( paste( "How many C->A: ", length(churn[ arch_n_1 > 0 ]$type) ))
    print( paste( "How many A->C: ", length(arch[ churn_n_1 > 0 ]$type) ))


    jumpsWith1StepBugs = jumps[bugs_n > 0]

    print( paste("Jumps 1step history from bugfix:", length(jumpsWith1StepBugs$type)))
    print( paste("How many of these are inducing bugs:", length(jumpsWith1StepBugs[type %like% "induce"]$type)))
    print( paste("ArchJumps:", length(jumpsWith1StepBugs[type %like% "arch"]$type)))
    print( paste("ChurnJump:", length(jumpsWith1StepBugs[type %like% "churn"]$type)))
    print( paste("INDUCE+ArchJumps:", length(jumpsWith1StepBugs[type %like% "arch" & type %like% "induce"]$type)))
    print( paste("INDUCE+ChurnJump:", length(jumpsWith1StepBugs[type %like% "churn" & type %like% "induce"]$type)))



    print( "General Statistics:")
    print( paste("Commits &", total , "&", 100,  "\\") )
    print( paste("Bug Fixing &", length(bugs$type) , "&", length(bugs$type) / total * 100 ,  "\\") )
    print( paste("Curn Jumps &", length(churn$type) , "&", length(churn$type) / total * 100,  "\\") )
    print( paste("Arch Jumps &", length(arch$type) , "&", length(arch$type) / total * 100,  "\\") )
    print( paste("Both Jumps &", length(bothjumps$type) , "&", length(bothjumps$type) / total * 100,  "\\") )
    print( paste("Jumps &", length(jumps$type) , "&", length(jumps$type) / total * 100,  "\\") )
    print( paste("Inducing B &", length(induce$type) , "&", length(induce$type) / total * 100,  "\\") )


    # How many architectural jumps are inducing bugs.




    # Bugs section
    if (length(bugs$type) > 0){
        print("------------")
        print("Bug Fixing commits history:")
        print("------------")

        total = length(bugs$type) / 100
        bf = length(bugs[bugs_pn>0]$type)
        cj = length(bugs[churn_pn>0]$type)
        aj = length(bugs[arch_pn>0]$type)
        either = length(bugsWithJumpsInHistory$type)
        both = length(bugs[arch_pn>0 & churn_pn >0 ]$type)


        cj1 = length(bugsWithJumpsInHistory[churn_pn_1>0]$type)
        aj1 = length(bugsWithJumpsInHistory[arch_pn_1>0]$type)
        either1step = length(bugsWithJumpsInHistory[arch_pn_1>0 | churn_pn_1 >0 ]$type)
        both1step = length(bugsWithJumpsInHistory[arch_pn_1>0 & churn_pn_1 >0 ]$type)






        cj1Induce = length(bugsWithJumpsInHistory[churn_pn>0][type %like% "induce"]$type)
        aj1Induce = length(bugsWithJumpsInHistory[arch_pn>0][type %like% "induce"]$type)
        either1stepInduce = length(bugsWithJumpsInHistory[arch_pn>0 | churn_pn >0 ][type %like% "induce"]$type)


        print( "Bug fixing commits that contain also large changes:" )
        print( paste("CJ &", cj, "&" , cj/total, "\\") )
        print( paste("AJ &", aj, "&" , aj/total, "\\") )



        print( paste("Either &", either, "&" , either/total, "\\") )
        print( paste("Both &", both, "&" , both/total, "\\") )
        print("------------")
        print("1 step:")
        print( paste("CJ &", cj1, "&" , cj1/total, "\\") )
        print( paste("AJ &", aj1, "&" , aj1/total, "\\") )
        print( paste("Either &", either1step, "&" , either1step/total, "\\") )
        print( paste("Both &", both1step, "&" , both1step/total, "\\") )

        print( "Induce 2step:" )
        print( paste("CJ &", cj1Induce, "&" , cj1Induce/total, "\\") )
        print( paste("AJ &", aj1Induce, "&" , aj1Induce/total, "\\") )
        print( paste("Either+Induce &", either1stepInduce, "&" , either1stepInduce/total, "\\") )

        # How many bug fixes have and Induce commit in their 2 step history:
        induceInHistory = length(bugs[induce_pn > 0]$type)
        print( paste("I &", induceInHistory, "&" , induceInHistory/total, "\\") )
        induceInHistory = length(bugs[induce_pn_1 > 0]$type)
        print( paste("I &", induceInHistory, "&" , induceInHistory/total, "\\") )

        # How many bug fixing commits have other bug fixing commits in their two step history
        print( paste("BF &", bf, "&" , bf/total, "\\") )

        # Distribution of large jumps in the history of a bugfix

        # bugsFollowed = data.table(CJ = bugs$churn_pn, AJ = bugs$arch_pn)[CJ > 0 | AJ > 0]
        # png(paste("data/",table,"/BugHistory.png", sep=""))
        # boxplot(bugsFollowed)
        # dev.off()

        # print("------------")
        # # BugFix commits stats
        # print( paste("BugFix preceeding commit labels normalised by number of nodes in history" ) )
        # print( paste("BF &", max(bugs$bugs_pn), "&", mean(bugs$bugs_pn), "&" , min(bugs$bugs_pn) , "\\") )
        # print( paste("CJ &", max(bugs$churn_pn), "&", mean(bugs$churn_pn), "&" , min(bugs$churn_pn) , "\\") )
        # print( paste("AJ &", max(bugs$arch_pn), "&", mean(bugs$arch_pn), "&" , min(bugs$arch_pn) , "\\") )
        # print( paste("I &", max(bugs$induce_pn), "&", mean(bugs$induce_pn), "&" , min(bugs$induce_pn) , "\\") )

    }

# nonBugs section
    swap = bugs
    bugs = nonBugs[!type %like% "induce"]
        if (length(bugs$type) > 0){
        print("------------")
        print("Bug Fixing commits history:")
        print("------------")

        total = length(bugs$type) / 100
        bf = length(bugs[bugs_pn>0]$type)
        cj = length(bugs[churn_pn>0]$type)
        aj = length(bugs[arch_pn>0]$type)
        both = length(bugs[arch_pn>0 | churn_pn >0 ]$type)
        either = length(bugs[arch_pn>0 & churn_pn >0 ]$type)


        cj1 = length(bugs[churn_pn_1>0]$type)
        aj1 = length(bugs[arch_pn_1>0]$type)
        both1 = length(bugs[arch_pn_1>0 | churn_pn_1 >0 ]$type)
        either1 = length(bugs[arch_pn_1>0 & churn_pn_1 >0 ]$type)

        print( "Bug fixing commits that contain also large changes:" )
        print( paste("CJ &", cj, "&" , cj/total, "\\") )
        print( paste("AJ &", aj, "&" , aj/total, "\\") )
        print( paste("Either &", both, "&" , both/total, "\\") )
        print( paste("Both &", either, "&" , either/total, "\\") )
        print("------------")
        print("1 step:")
        print( paste("CJ &", cj1, "&" , cj1/total, "\\") )
        print( paste("AJ &", aj1, "&" , aj1/total, "\\") )
        print( paste("Either &", both1, "&" , both1/total, "\\") )
        print( paste("Both &", either1, "&" , either1/total, "\\") )

        # How many bug fixes have and Induce commit in their 2 step history:
        induceInHistory = length(bugs[induce_pn > 0]$type)
        print( paste("I &", induceInHistory, "&" , induceInHistory/total, "\\") )

        # How many bug fixing commits have other bug fixing commits in their two step history
        print( paste("BF &", bf, "&" , bf/total, "\\") )

        # Distribution of large jumps in the history of a bugfix
        # bugsFollowed = data.table(CJ = bugs$churn_pn, AJ = bugs$arch_pn)[CJ > 0 | AJ > 0]
        # png(paste("data/",table,"/BugHistory.png", sep=""))
        # boxplot(bugsFollowed)
        # dev.off()

        # print("------------")
        # # BugFix commits stats
        # print( paste("BugFix preceeding commit labels normalised by number of nodes in history" ) )
        # print( paste("BF &", max(bugs$bugs_pn), "&", mean(bugs$bugs_pn), "&" , min(bugs$bugs_pn) , "\\") )
        # print( paste("CJ &", max(bugs$churn_pn), "&", mean(bugs$churn_pn), "&" , min(bugs$churn_pn) , "\\") )
        # print( paste("AJ &", max(bugs$arch_pn), "&", mean(bugs$arch_pn), "&" , min(bugs$arch_pn) , "\\") )
        # print( paste("I &", max(bugs$induce_pn), "&", mean(bugs$induce_pn), "&" , min(bugs$induce_pn) , "\\") )

    }
    bugs = swap


# Induce section
    bugs = induce
        if (length(bugs$type) > 0){
        print("------------")
        print("Bug Fixing commits history:")
        print("------------")

        total = length(bugs$type) / 100
        bf = length(bugs[bugs_pn>0]$type)
        cj = length(bugs[churn_pn>0]$type)
        aj = length(bugs[arch_pn>0]$type)
        both = length(bugs[arch_pn>0 | churn_pn >0 ]$type)
        either = length(bugs[arch_pn>0 & churn_pn >0 ]$type)


        cj1 = length(bugs[churn_pn_1>0]$type)
        aj1 = length(bugs[arch_pn_1>0]$type)
        both1 = length(bugs[arch_pn_1>0 | churn_pn_1 >0 ]$type)
        either1 = length(bugs[arch_pn_1>0 & churn_pn_1 >0 ]$type)

        print( "Bug fixing commits that contain also large changes:" )
        print( paste("CJ &", cj, "&" , cj/total, "\\") )
        print( paste("AJ &", aj, "&" , aj/total, "\\") )
        print( paste("Either &", both, "&" , both/total, "\\") )
        print( paste("Both &", either, "&" , either/total, "\\") )
        print("------------")
        print("1 step:")
        print( paste("CJ &", cj1, "&" , cj1/total, "\\") )
        print( paste("AJ &", aj1, "&" , aj1/total, "\\") )
        print( paste("Either &", both1, "&" , both1/total, "\\") )
        print( paste("Both &", either1, "&" , either1/total, "\\") )

        # How many bug fixes have and Induce commit in their 2 step history:
        induceInHistory = length(bugs[induce_pn > 0]$type)
        print( paste("I &", induceInHistory, "&" , induceInHistory/total, "\\") )

        # How many bug fixing commits have other bug fixing commits in their two step history
        print( paste("BF &", bf, "&" , bf/total, "\\") )

        # Distribution of large jumps in the history of a bugfix
        # bugsFollowed = data.table(CJ = bugs$churn_pn, AJ = bugs$arch_pn)[CJ > 0 | AJ > 0]
        # png(paste("data/",table,"/BugHistory.png", sep=""))
        # boxplot(bugsFollowed)
        # dev.off()

        # print("------------")
        # # BugFix commits stats
        # print( paste("BugFix preceeding commit labels normalised by number of nodes in history" ) )
        # print( paste("BF &", max(bugs$bugs_pn), "&", mean(bugs$bugs_pn), "&" , min(bugs$bugs_pn) , "\\") )
        # print( paste("CJ &", max(bugs$churn_pn), "&", mean(bugs$churn_pn), "&" , min(bugs$churn_pn) , "\\") )
        # print( paste("AJ &", max(bugs$arch_pn), "&", mean(bugs$arch_pn), "&" , min(bugs$arch_pn) , "\\") )
        # print( paste("I &", max(bugs$induce_pn), "&", mean(bugs$induce_pn), "&" , min(bugs$induce_pn) , "\\") )

    }
    bugs = swap


    if (length(bugs$type) > 0){
        print("------------")
        print("How many Bug-Fixes commits are also jumps?")
        print("------------")
        # How many Bug-Fixes commits are also jumps?
        archbugs = length( bugs[type %like% "arch"]$type)
        churnbugs = length( bugs[type %like% "churn"]$type)
        eitherbugs = length( bugs[type %like% "arch" | type %like% "churn"]$type)
        bothbugs = length( bugs[type %like% "arch" & type %like% "churn"]$type)
        print( paste("Arch Jump  :", archbugs) )
        print( paste("Curn Jump  :", churnbugs) )
        print( paste("Either Jump:", eitherbugs) )
        print( paste("Both Jumps :", bothbugs) )
    }

    # Induce section
    if (length(induce$type) > 0){
        print("------------")
        print("Bug Inducing commits that are also jumps:")
        print("------------")

        # How many Inducing commits are also jumps?
        bugInduce = length( induce[type %like% "bug"]$type)
        bugInduceJump = length( induce[type %like% "bug"][type %like% "arch" | type %like% "churn"]$type)
        archInduce = length( induce[type %like% "arch"]$type)
        churnInduce = length( induce[type %like% "churn"]$type)
        eitherInduce = length( induce[type %like% "arch" | type %like% "churn"]$type)
        bothInduce = length( induce[type %like% "arch" & type %like% "churn"]$type)

        print( paste("Bug-fixs inducing more bugs:", bugInduce) )
        print( paste("Bug-fixs inducing more bugs if they are jumps:", bugInduceJump) )
        print( paste("Arch Jump  :", archInduce) )
        print( paste("Curn Jump  :", churnInduce) )
        print( paste("Either Jump:", eitherInduce) )
        print( paste("Both Jumps :", bothInduce) )



        png(paste("data/",table,"/Pre_Induce.png", sep=""))
        boxplot(data.table(bugs = induce$bugs_pn, churn = induce$churn_pn, arch = induce$arch_pn))
        dev.off()

    }


    print("------------")
    print("Research Questions:")
    print("------------")
    # Research questions
    # RQ1
    induceCommitsAreJumps = myTable[type %like% "induce" & type %like% "churn" | type %like% "induce" & type %like% "churn" ]
    print( "RQ1: How many of the bug inducing commits are also large changes:")
    print( length(induceCommitsAreJumps$type) )

    # RQ2
    induceCommitsAreArchJumps = myTable[type %like% "induce" & type %like% "arch"]
    print( "RQ2: How many of the bug inducing commits are large architectural changes:")
    print( length(induceCommitsAreArchJumps$type) )

    # RQ3
    print( "RQ3: What is the distrubition of combinations of large changes in the two step history of a bug fixing commit.")
    precedenceBugs = myPrecedenceTable[Type %like% "bug"]
    nonEmpty = precedenceBugs[AC > 0 | CA > 0]
    if (length(nonEmpty$Type) > 0){
        normalisedCombinations = data.table(ca = nonEmpty$ca, aa = nonEmpty$aa, cc = nonEmpty$cc, ac = nonEmpty$ac)
        nc = normalisedCombinations
        png(paste("data/",table,"/Precedence.png", sep=""))
        boxplot(normalisedCombinations)
        dev.off()

        print("------------")

        print( paste("CAn &", max(nc$ca), "&", mean(nc$ca), "&" , min(nc$ca) , "\\") )
        # print( paste("AAn &", max(nc$aa), "&", mean(nc$aa), "&" , min(nc$aa) , "\\") )
        # print( paste("CCn &", max(nc$cc), "&", mean(nc$cc), "&" , min(nc$cc) , "\\") )
        print( paste("ACn &", max(nc$ac), "&", mean(nc$ac), "&" , min(nc$ac) , "\\") )
        print("------------")
    }

    nonEmpty = precedenceBugs[AC >0 | CA > 0]
    if (length(nonEmpty$Type) > 0){
        nc = data.table(ca = nonEmpty$ca, ac = nonEmpty$ac)
        png(paste("data/",table,"/PrecedenceAC_CA.png", sep=""))
        boxplot(nc)
        dev.off()
    }

    # commits with the label bug
    BAC = length(myPrecedenceTable[Type %like% "bug" & AC > 0]$Type)
    # Commits without the label bug
    XBAC = length(myPrecedenceTable[!Type %like% "bug" & AC > 0]$Type)
    print( paste("Bug<-Arch<-Churn", BAC ))
    print( paste("NonBug<-Arch<-Churn", XBAC ))
    print("------------")

    print( "RQ4: What is the distrubition of combinations of large changes in the two step history of a bug inducing commits.")
    precedenceBugs = myPrecedenceTable[Type %like% "induce"]
    nonEmpty = precedenceBugs[AC > 0 | CA > 0]
     if (length(nonEmpty$Type) > 0){
        normalisedCombinations = data.table(ca = nonEmpty$ca, aa = nonEmpty$aa, cc = nonEmpty$cc, ac = nonEmpty$ac)
        nc = normalisedCombinations
        png(paste("data/",table,"/InducePrecedence.png", sep=""))
        boxplot(normalisedCombinations)
        dev.off()

        print("------------")
        print( paste("CAn &", max(nc$ca), "&", mean(nc$ca), "&" , min(nc$ca) , "\\") )
        # print( paste("AAn &", max(nc$aa), "&", mean(nc$aa), "&" , min(nc$aa) , "\\") )
        # print( paste("CCn &", max(nc$cc), "&", mean(nc$cc), "&" , min(nc$cc) , "\\") )
        print( paste("ACn &", max(nc$ac), "&", mean(nc$ac), "&" , min(nc$ac) , "\\") )
        print("------------")
    }

    # commits with the label bug
    IAC = length(myPrecedenceTable[Type %like% "induce" & AC > 0]$Type)
    # Commits without the label bug
    XIAC = length(myPrecedenceTable[!Type %like% "induce" & AC > 0]$Type)
    print( paste("Induce<-Arch<-Churn", IAC ))
    print( paste("NonInduce<-Arch<-Churn", XIAC ))
    print("------------")

}


