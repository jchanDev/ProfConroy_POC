#Load the data
data<-read.csv("human-data/processed-data/CSM-Match-matching-data.csv")

#Number of Observations#
#Total number of observation opportunities agents will have in mate search
nobs<-30*nrow(data)/2

#MV calculation#
mvCalc <- function(ideal,
                   ageDq,
                   raceDq,
                   religionDq,
                   politicsDq,
                   traits,
                   age,
                   race,
                   religion,
                   politics) {
  #ideal is ideal preferences
  #ageDq is age disqualifiers
  #raceDq is race disqualifiers
  #religionDq is religion disqualifiers
  #politicsDq is politics disqualifiers
  #traits is actual trait values
  #age is age of the participant
  #race is participants' race/ethnicity
  #religion is participants' religion
  #politics is participants' politics
  
  
  
  #Continuous Preferences#
  
  #Calculates Euclidean distance between preferences and traits
  #Transforms this distance such that positive values are more attractive
  mv <- apply(traits, 1, function(x)
    sum((ideal - x) ^ 2))
  
  
  
  #Disqualifiers#
  
  #Age:
  
  #Create a variable for translating age to DQ caterogires
  ageCat <- data.frame("age" = c(18:22, "23_25", 26),
                       "cat" = 1:7)
  
  #Convert age to their corresponding DQ categories
  selfAge <- sapply(age, function(x)
    ifelse(x >= 26, 7, ifelse(x >= 23 & x <= 25, 6,
                              ageCat$cat[match(x, ageCat$age)])))
  
  #Determine MV points each potential mate should receive based on age
  ageDqMV <- sapply(selfAge, function(x)
    ifelse(x %in% which(ageDq == 1), 0, 2))
  
  
  
  #Race:
  
  #Determine how many MV points each potential mate should receive based on race/ethnicity
  raceDqMV <- apply(race, 1, function(x)
    ifelse(sum(
      as.numeric(raceDq) * as.numeric(x), na.rm = T
    ) > 0, 0, 2))
  
  
  
  #Religion:
  
  #Determine how many MV points each potential mate should received based on religion
  religionDqMV <- sapply(religion, function(x)
    ifelse(x %in% which(religionDq == 1), 0, 2))
  
  
  #Politics:
  
  #Determine how many MV points each potential mate should received based on politics
  politicsDqMV <- sapply(politics, function(x)
    ifelse(x %in% which(politicsDq == 1), 0, 2))
  
  
  #Add DQs to mv total and compute distance
  mv <- sqrt(mv + ageDqMV ^ 2 + raceDqMV ^ 2 + religionDqMV ^ 2 + politicsDqMV ^
               2)
  
  #Compute MV including preferences and disqualifiers
  mv <- (-1 * mv + sqrt(10 ^ 2 * 19)) / sqrt(10 ^ 2 * 19)
  
  return(mv)
  
}


#Improved Sampling#
#A sample function that will return a single scalar if given it
resample <- function(x, ...) {
  
  if (length(x) == 1) {
    x
  } else {
    sample(x, ...)
  }
  
}



mateChoice <- function(data) {
  
  
  #Break data into females and males
  females <- data[data$sex == 0, ]
  males <- data[data$sex == 1, ]
  
  
  ###MV Calculation###
  
  #Males
  #Calculate the mate value of each female to each male given starting preferences
  maleMvMatrix <- t(apply(males, 1, function(x)
    mvCalc(x[45:59],
           x[29:35],
           x[4:9],
           x[10:21],
           x[22:28],
           females[,60:74],
           females[,3],
           females[,36:41],
           females[,43],
           females[,44])))
  
  
  
  #Females
  #Calculate the mate value of each male to each female given starting preferences
  femaleMvMatrix <- t(apply(females, 1, function(x)
    mvCalc(x[45:59],
           x[29:35],
           x[4:9],
           x[10:21],
           x[22:28],
           males[,60:74],
           males[,3],
           males[,36:41],
           males[,43],
           males[,44])))
  
  
  
  ### Observation Trials ###
  
  #Generate dataframes to store the number of visits
  investMale <- matrix(1, nrow(males), nrow(females))
  investFemale <- matrix(1, nrow(females), nrow(males))
  
  #Generate matrices to track history of reciprocity
  recipHistMale <- matrix(1, nrow(males), nrow(females))
  recipHistFemale <- matrix(1, nrow(females), nrow(males))
  
  #Loop through observation opportunities
  for (o in 1:nobs) {
    mReward <- maleMvMatrix * recipHistMale
    fReward <- femaleMvMatrix * recipHistFemale
    
    #Choose the partner with the highest MV, weighted by reciprocity
    choiceMale <- cbind(1:nrow(males),
                        apply(mReward, 1, function(x)
                          resample(which(x == max(
                            x
                          )), 1)))
    
    choiceFemale <- cbind(1:nrow(females),
                          apply(fReward, 1, function(x)
                            resample(which(x == max(
                              x
                            )), 1)))
    
    #Update observation counts
    investMale[choiceMale] <- investMale[choiceMale] + 1
    investFemale[choiceFemale] <- investFemale[choiceFemale] + 1
    
    #Update reciprocity histories
    recipHistMale <- (t(investFemale) / investMale)
    recipHistFemale <- (t(investMale) / investFemale)
    
  }
  
  
  #Determine which female in which each males has invested most
  #Break ties randomly
  mChoice <- data.frame("male" = 1:nrow(males))
  mChoice$choice <- apply(investMale, 1, function(x)
    resample(which(x == max(x)), 1))
  
  #Determine which male in which each female has invested most
  #Break ties randomly
  fChoice <- data.frame("female" = 1:nrow(females))
  fChoice$choice <- apply(investFemale, 1, function(x)
    resample(which(x == max(x)), 1))
  
  
  #Determine which choices represent a mutual match
  mChoice$match <- (1:nrow(males)) == fChoice$choice[mChoice$choice]
  fChoice$match <- (1:nrow(females)) == mChoice$choice[fChoice$choice]
  
  #Add chosen mate PINs to the male and female dataframes
  males$mPIN <- females$PIN[mChoice$choice]
  females$mPIN <- males$PIN[fChoice$choice]
  
  males$mPIN[mChoice$match == 0] <- NA
  females$mPIN[fChoice$match == 0] <- NA
  
  #Output the data with matches
  return(rbind(females, males))
}

#Timestamp the filename:

path<-"model-outputs/csm-match-human-data-MATCHED-"

format<-".csv"
date<-format(Sys.time(),format="%Y%m%d-%H%M%S")
file<-file.path(paste0(path,date,format))

write.csv(dataMatched,file=file,row.names=F)
