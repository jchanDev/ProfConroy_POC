#Load the data
data<-read.csv("CSM_Match_Mock_Data_20230720_164351.csv")





#Number of Observations#
#Total number of observation opportunities agents will have in mate search
nobs<-30*nrow(data)/2







#MV calculation#
mvCalc <- function(ideal, traits) {
  
  #ideal is ideal preferences
  #traits is actual trait values
  
  #Calculates Euclidean distance between preferences and traits
  #Transforms this distance such that positive values are more attractive
  mv <- apply(traits, 1, function(x)
    (-1 * (dist(rbind(ideal, x))) +
      sqrt(10 ^ 2 * 16)) / 
      sqrt(10 ^ 2 * 16))
  
  return(mv)
  
}



#Improved Sampling#
#A sample function that will return a single scalar if given it
resample <- function(x, ...) {
  
  if (length(x) == 1) {
    x
  } else {
    sample(
        x, ...)
  }
  
}



mateChoice <- function(data) {
  
  
  #Break data into females and males
  females <- data[data$sex == 0, ]
  males <- data[data$sex == 1, ]
  
  
  ###MV Calculation###
  
  #Males
  #Calculate the mate value of each female to each male given starting preferences
  maleMvMatrix <- t(apply(males[, 38:53], 1, function(x)
    mvCalc(x, females[, 54:69])))
  
  
  
  #Females
  #Calculate the mate value of each male to each female given starting preferences
  femaleMvMatrix <- t(apply(females[, 38:53], 1, function(x)
    mvCalc(x, males[, 54:69])))
  
  
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



dataMatched<-mateChoice(data)

#Timestamp the filename:

path <-"/tmp"

format <-".csv"
date <- format(Sys.time(),format="%Y%m%d_%H%M%S")
csvfilename <- paste("MockData_", date, ".csv", sep = "")
file <- file.path(path, csvfilename)

return_csvfilename <- function() {
  return(cat(csvfilename))
}
return_csvfilename()  

write.csv(dataMatched, file = file, row.names = FALSE)