library(dplyr)
library(readr)
library(ggplot2)

NCAAF_L1 <- read_csv("https://raw.githubusercontent.com/MattC137/Open_Data/master/Data/Sports/NCAAF/NCAAF_Level_One.csv")
NCAAF_L1_Teams <- read_csv("https://raw.githubusercontent.com/MattC137/Open_Data/master/Data/Sports/NCAAF/NCAAF_Team_List.csv")

#### Setup ####

NCAAF_L1_Future <- NCAAF_L1 %>% 
  filter(Played == FALSE, Game_ID != "Canceled", Game_ID != "Postponed")

NCAAF_L1 <- NCAAF_L1 %>% 
  filter(Played == TRUE) %>% 
  arrange(Date, Game_ID)

NCAAF_L1 <- NCAAF_L1 %>% mutate(
  ELO = 0,
  Opp_ELO = 0,
  Result = ifelse(Result == "W", 1, Result),
  Result = ifelse(Result == "L", 0, Result),
  Result = ifelse(Result == "T", 0.5, Result),
  Result = as.numeric(Result)
)

NCAAF_L1_Teams <- NCAAF_L1_Teams %>% mutate(
  ELO = ifelse(FBS == 1, 1500, 1200),
)

#### ELO ####

for(i in 1:nrow(NCAAF_L1)){
  if(i %% 2 != 0){
    # i = 1
    print(i)
    
    # View(head(NCAAF_L1))
    
    Team_A <- NCAAF_L1$Team[i]
    Team_B <- NCAAF_L1$Team[i+1]
    
    Result_A <- NCAAF_L1$Result[i]
    Result_B <- NCAAF_L1$Result[i+1]
    
    ## Get Current ELO ##
    
    ELO_A <- as.numeric(NCAAF_L1_Teams[NCAAF_L1_Teams$Team == Team_A, "ELO"])
    ELO_B <- as.numeric(NCAAF_L1_Teams[NCAAF_L1_Teams$Team == Team_B, "ELO"])
    
    ## Load current ELO into the main dataset ##
    
    NCAAF_L1$ELO[i] <- ELO_A
    NCAAF_L1$Opp_ELO[i] <- ELO_B
    
    NCAAF_L1$ELO[i+1] <- ELO_B
    NCAAF_L1$Opp_ELO[i+1] <- ELO_A
    
    # View(NCAAF_L1 %>% select(Date, Season, Team, Opponent, Result, Points_For, Points_Against, ELO, Opp_ELO))
    
    ## Update ELOs
    
    R_A <- 10^(ELO_A/400)
    R_B <- 10^(ELO_B/400)
    
    E_A <- R_A/(R_A + R_B)
    E_B <- R_B/(R_A + R_B)
    
    Elo_Updated_A <- ELO_A + 40 * (Result_A - E_A)
    Elo_Updated_B <- ELO_B + 40 * (Result_B - E_B)
    
    ## Update Team ELOs
    
    NCAAF_L1_Teams[NCAAF_L1_Teams$Team == Team_A, "ELO"] <- Elo_Updated_A
    NCAAF_L1_Teams[NCAAF_L1_Teams$Team == Team_B, "ELO"] <- Elo_Updated_B
    
  }
}

View(NCAAF_L1_Teams %>% filter(FBS == 1) %>% arrange(desc(ELO)) %>% top_n(25))


#Naive wins
NCAAF_L1 <- NCAAF_L1 %>% mutate(
  ELO = as.numeric(ELO),
  Opp_ELO = as.numeric(Opp_ELO),
  Elo_Difference = ELO - Opp_ELO,
  Elo_Forecast_Pred = ifelse(ELO > Opp_ELO, 1, 0),
  Elo_Forecast_Result = ifelse(Elo_Forecast_Pred == Result, 1, 0),
)

#### 2016 Naive Win Rate ####
Results_2016 <- NCAAF_L1 %>% filter(Season == 2016)
sum(Results_2016$Elo_Forecast_Result)/nrow(Results_2016) * 100

#### 2017 Naive Win Rate ####
Results_2017 <- NCAAF_L1 %>% filter(Season == 2017)
sum(Results_2017$Elo_Forecast_Result)/nrow(Results_2017) * 100

#### 2018 Naive Win Rate ####
Results_2018 <- NCAAF_L1 %>% filter(Season == 2018)
sum(Results_2018$Elo_Forecast_Result)/nrow(Results_2018)  * 100

#### 2019 Naive Win Rate ####
Results_2019 <- NCAAF_L1 %>% filter(Season == 2019)
sum(Results_2019$Elo_Forecast_Result)/nrow(Results_2019) * 100

#### 2000-2019 Naive Win Rate ####
Results_all <- NCAAF_L1 %>% filter(Season >= 2000 & Season <= 2019)
sum(Results_all$Elo_Forecast_Result)/nrow(Results_all) * 100

#### Spread Forecast ####
spread_lm_1 <- lm(Spread ~ Elo_Difference + Home, data = NCAAF_L1 %>% filter(Season > 2013, Season <= 2018))
NCAAF_L1$Spread_Pred_lm_1 <- predict(spread_lm_1, newdata = NCAAF_L1)
Results_2019$Spread_Pred_lm_1 <- predict(spread_lm_1, newdata = Results_2019)

#### Win Forecast ####
win_prob_glm_1 <- glm(Result ~ Elo_Difference + Home, family = binomial, NCAAF_L1 %>% filter(Season > 2013, Season <= 2018))
NCAAF_L1$win_prob_glm_1 <- predict(win_prob_glm_1, newdata = NCAAF_L1, type = "response")

#### Spread Forecast All ####
spread_lm_2 <- lm(Spread ~ Elo_Difference + Home, data = NCAAF_L1 %>% filter(Season >= 2000, Season <= 2018))
NCAAF_L1$Spread_Pred_lm_2 <- predict(spread_lm_2, newdata = NCAAF_L1)
Results_2019$Spread_Pred_lm_2 <- predict(spread_lm_2, newdata = Results_2019)

#### Win Forecast All ####
win_prob_glm_2 <- glm(Result ~ Elo_Difference + Home, family = binomial, NCAAF_L1 %>% filter(Season >= 2000, Season <= 2018))
NCAAF_L1$win_prob_glm_2 <- predict(win_prob_glm_2, newdata = NCAAF_L1, type = "response")

#### Test Model####
Results_2019$win_prob_glm_1 <- predict(win_prob_glm_1, newdata = Results_2019)
Results_2019$win_prob_glm_1 <- ifelse(Results_2019$Spread_Pred_lm_1 >= 0.5, 1, 0)
sum(Results_2019$win_prob_glm_1 == Results_2019$Result )/nrow(Results_2019) * 100

Results_2019$win_prob_glm_2 <- predict(win_prob_glm_2, newdata = Results_2019)
Results_2019$win_prob_glm_2 <- ifelse(Results_2019$Spread_Pred_lm_2 >= 0.5, 1, 0)
sum(Results_2019$win_prob_glm_2 == Results_2019$Result )/nrow(Results_2019) * 100

ggplot(Results_2019) + geom_point(aes(x = Spread, y = Spread_Pred_lm_1))
ggplot(Results_2019) + geom_point(aes(x = Spread, y = Spread_Pred_lm_2))
