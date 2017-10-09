#########################################
# ����: ��������
# ����������: 2017.09.20
# �ۼ���: ���ϱ�
#########################################
#��Ű�� ��ġ �� �ε�
library(reshape2)
library(data.table)
library(ggplot2)
library(dplyr)
library(caret)
library(e1071)
library(class)
library(h2o)
localH2O=h2o.init()
#2016/01~2016/12�� ���������ͷ� 2016/10~12���� 2017/10~12�� ������ ���� (logerror predict)
setwd("C:/Users/il-geun/Desktop/zillow")
train1 <- fread("train_2016_v2.csv",header=T)  #�ŷ��� �ִ� ������ => �ѹ��� �������ΰ� ��� ó��? �������� �ȴ޶���
train2 <- fread("train_2017.csv",header=T)
train <- rbind(train1, train2)

properties1 <- fread("properties_2016.csv", header = T, stringsAsFactors = T)
properties2 <- fread("properties_2017.csv", header = T, stringsAsFactors = T)
properties <- rbind(properties1, properties2)
summary(properties)
#2016�⿡�� ���������� 2017�⿡�� �ִ°Ű� ���� -> �������� ���� / 2016�� ���� ������ �ٲ���� ���ɼ����� ��  

sub <- fread("sample_submission.csv",header=T)

pro_na2 <- properties1[properties1$parcelid %in% properties2[is.na(properties2$latitude),]$parcelid ,]
properties2 <-  rbind(properties2[!is.na(properties2$latitude),], pro_na2)

pro_na1 <- properties2[properties2$parcelid %in% properties1[is.na(properties1$latitude),]$parcelid ,]
properties1 <-  rbind(properties1[!is.na(properties1$latitude),], pro_na1)

properties1$censustractandblock[properties1$censustractandblock == -1] <- NA #3�ǻ� => ����ó��
properties2$censustractandblock[properties2$censustractandblock == -1] <- NA 

#summary(properties1$assessmentyear)
#p1 <- properties %>% 
#       group_by(parcelid) %>% 
#       summarise(diff(structuretaxvaluedollarcnt))
#summary(p1)
#diff(c(NA,99))
#properties <- properties[duplicated(properties) == F ,] #5966749

train$year <- as.factor(substr(train$transactiondate,1,4))
train$month <- as.factor(as.numeric(substr(train$transactiondate,6,7)))
#train�� �ִ� ������� ��� sub�� �ֱ� 
colnames(train)[1] <- "ParcelId"
sub <- merge(sub, subset(train[train$year=="2016" & train$month == "10",], select = c("ParcelId", "logerror") ), by = "ParcelId", all.x = T)
colnames(sub)[ncol(sub)] <- "log201610"
sub <- merge(sub, subset(train[train$year=="2016" & train$month == "11",], select = c("ParcelId", "logerror") ), by = "ParcelId", all.x = T)
colnames(sub)[ncol(sub)] <- "log201611"
sub <- merge(sub, subset(train[train$year=="2016" & train$month == "12",], select = c("ParcelId", "logerror") ), by = "ParcelId", all.x = T)
colnames(sub)[ncol(sub)] <- "log201612"

m_y <- train %>%
  group_by(year, month) %>%
  summarise(mm = mean(logerror))
plot(m_y$mm) #���⼺�� ����

properties <- properties1

#data �÷��� Ÿ�� ��ȯ
properties$rawcensustractandblock <- as.factor(properties$rawcensustractandblock)
properties$censustractandblock <- as.factor(properties$censustractandblock)
properties$regionidzip <- as.factor(properties$regionidzip)
properties$regionidcounty <- as.factor(properties$regionidcounty)
properties$regionidcity <- as.factor(properties$regionidcity) #1803�� ����
properties$fips <- as.factor(properties$fips)# Federal Information Processing Standard code
properties$propertylandusetypeid <- as.factor(properties$propertylandusetypeid) #���� x
#properties$propertycountylandusecode <- as.factor(properties$propertycountylandusecode) #�ڵ尡 �ʹ� �پ� (1)
#properties$propertyzoningdesc <- as.factor(properties$propertyzoningdesc)             # �ڵ尡 �ʹ� �پ�(31962)


#properties$hashottuborspa <- as.factor(properties$hashottuborspa) #���Ŀ���
#properties$fireplaceflag <- as.factor(properties$fireplaceflag) 
#properties$taxdelinquencyflag <- as.factor(properties$taxdelinquencyflag) 
#���浵 �α׺�ȯ
properties$latitude <- log(properties$latitude)
properties$longitude <- log(abs(properties$longitude))

#�ʿ���� �÷� ����
#properties <- subset(properties,select=c(-assessmentyear))
summary(properties)
properties$storytypeid[is.na(properties$storytypeid)] <- "na"
properties$storytypeid <- as.factor(properties$storytypeid)
properties$pooltypeid2[is.na(properties$pooltypeid2)] <- "na"
properties$pooltypeid2 <- as.factor(properties$pooltypeid2)
properties$pooltypeid7[is.na(properties$pooltypeid7)] <- "na"
properties$pooltypeid7 <- as.factor(properties$pooltypeid7)
properties$pooltypeid10[is.na(properties$pooltypeid10)] <- "na"
properties$pooltypeid10 <- as.factor(properties$pooltypeid10)
properties$decktypeid[is.na(properties$decktypeid)] <- "na"
properties$decktypeid <- as.factor(properties$decktypeid)
properties$buildingclasstypeid[is.na(properties$buildingclasstypeid)] <- "na"
properties$buildingclasstypeid <- as.factor(properties$buildingclasstypeid)

#
properties$airconditioningtypeid[is.na(properties$airconditioningtypeid)] <- "na"
properties$airconditioningtypeid <- as.factor(properties$airconditioningtypeid)
properties$architecturalstyletypeid[is.na(properties$architecturalstyletypeid)] <- "na"
properties$architecturalstyletypeid <- as.factor(properties$architecturalstyletypeid)
properties$buildingqualitytypeid[is.na(properties$buildingqualitytypeid)] <- "na"
properties$buildingqualitytypeid <- as.factor(properties$buildingqualitytypeid)
properties$heatingorsystemtypeid[is.na(properties$heatingorsystemtypeid)] <- "na"
properties$heatingorsystemtypeid <- as.factor(properties$heatingorsystemtypeid)
properties$typeconstructiontypeid[is.na(properties$typeconstructiontypeid)] <- "na"
properties$typeconstructiontypeid <- as.factor(properties$typeconstructiontypeid)


properties$regionidneighborhood[is.na(properties$regionidneighborhood)] <- "na"
properties$regionidneighborhood <- as.factor(properties$regionidneighborhood)
properties$typeconstructiontypeid[is.na(properties$typeconstructiontypeid)] <- "na"
properties$typeconstructiontypeid <- as.factor(properties$typeconstructiontypeid)

#�̷��� 2�� 1�� ��ü (������ Ư���� ��ġ�� ����)
#properties1[is.na(properties1$fips),]
#properties2[is.na(properties2$fips),]

#properties1[is.na(properties1$latitude),]
#properties2[is.na(properties2$latitude),]

summary(properties)
properties$censustractandblock <- as.character(properties$censustractandblock)
properties$censustractandblock[is.na(properties$censustractandblock)] <- "na"
properties$censustractandblock <- as.factor(properties$censustractandblock)
censustractandblock

#��ġ�� ����
#�̻� ������ ó�� �ʿ� => �����Ϳ� ���� ���ذ� ������ �Ǿ���. �������� ó���ʿ�


#regionidcounty(�ε�����ġ�� ���� 0 ���ε��� 3101�� �� �ְ�, 3101���� ����)
#typeconstructiontypeid, fireplaceflag �� �� 1�� �̻��� ���� ����
summary(as.factor(properties[properties$roomcnt == 0, ]$typeconstructiontypeid ))
properties$typeconstructiontypeid[properties$roomcnt == 0 & properties$typeconstructiontypeid =="11" ] <- NA
summary(as.factor(properties[properties$roomcnt == 0, ]$fireplaceflag )) #���� �̻󰪿� ���Ե� => ��������
properties$fireplaceflag[properties$roomcnt == 0 & properties$fireplaceflag != "" ] <- ""


#�������� ���� ������ �ؾ���
plot(basementsqft~logerror,set) #������ ���� (90232) => 0ó��(���ٰ� ����)
properties$basementsqft[is.na(properties$basementsqft)] <- 0

#calcul�̶� ��� ���� ���� (6,12,13,15) - cor 1 => ���η� �ٲٴ°� ������
plot(calculatedfinishedsquarefeet~logerror,set) #�Ƕ�̵��(661)
plot(finishedsquarefeet6~logerror,set) #Base unfinished and finished area (89854) #��κ� ����, ���� 1��
plot(finishedsquarefeet12~logerror,set) #Finished living area �Ƕ�̵��(4679)
plot(finishedsquarefeet13~logerror,set) #Perimeter  living area (90242) #��κ� ����, 1����
plot(finishedsquarefeet15~logerror,set) #Total area             (86711) #��κ� ����, �Ƕ�̵� ����
cor(properties[,c(12,17)],use ="complete.obs")
cor(properties[,c(12,13)],use ="complete.obs")
cor(properties[,c(12,14)],use ="complete.obs")
cor(properties[,c(12,15)],use ="complete.obs")
properties$finishedsquarefeet6[!is.na(properties$finishedsquarefeet6)] <- 1
properties$finishedsquarefeet6[is.na(properties$finishedsquarefeet6)] <- 0
properties$finishedsquarefeet6 <- as.factor(properties$finishedsquarefeet6)

properties$finishedsquarefeet12[!is.na(properties$finishedsquarefeet12)] <- 1
properties$finishedsquarefeet12[is.na(properties$finishedsquarefeet12)] <- 0
properties$finishedsquarefeet12 <- as.factor(properties$finishedsquarefeet12)

properties$finishedsquarefeet13[!is.na(properties$finishedsquarefeet13)] <- 1
properties$finishedsquarefeet13[is.na(properties$finishedsquarefeet13)] <- 0
properties$finishedsquarefeet13 <- as.factor(properties$finishedsquarefeet13)

properties$finishedsquarefeet15[!is.na(properties$finishedsquarefeet15)] <- 1
properties$finishedsquarefeet15[is.na(properties$finishedsquarefeet15)] <- 0
properties$finishedsquarefeet15 <- as.factor(properties$finishedsquarefeet15)

plot(finishedfloor1squarefeet~logerror,set) # ���� 1���� (�����?)- (83419) 
plot(finishedsquarefeet50~logerror,set) #  Size of the finished living area on the first (entry) floor of the home (83419) #��κ� ���� 1�� �����
cor(properties[,c(11,16)],use ="complete.obs")
properties$finishedfloor1squarefeet[is.na(properties$finishedfloor1squarefeet)] <- 0
properties <- subset(properties, select= -c(finishedsquarefeet50))

#garagecar cnt => ������ �����͵� 0�� => �������� -999�� ����
boxplot(logerror ~ addNA(garagecarcnt), set) 
plot(garagecarcnt~logerror,set) # ��κа���(60338) #�Ƕ�̵� ���� 
plot(garagetotalsqft~logerror,set) # ��κа���(60338)  #�Ƕ�̵� ����
properties$garagecarcnt[is.na(properties$garagecarcnt)] <- -999
properties$garagetotalsqft[is.na(properties$garagetotalsqft)] <- -999


#summary(properties$fireplaceflag) ,nrow(properties[!is.na(properties$fireplacecnt),]) #�� �����ο��ζ�, ������ �ȸ�����?
plot(fireplacecnt~logerror,set) # ��κа���(80668) #�Ƕ�̵� ���� #������ ���� �������� 0���� 
properties$fireplacecnt[is.na(properties$fireplacecnt)] <- 0

#������ ���ú���(��κ� ���ǹ��ϱ� ��)
summary(properties[,28:32])
summary(properties[is.na(properties$poolcnt)]$poolsizesum)
plot(poolsizesum~logerror,set) #��κ� ���� (89306) #���� 1��
properties$poolsizesum[is.na(properties$poolcnt)] <- 0
properties$poolcnt[is.na(properties$poolcnt)] <- 0

#����, ����� ������ => ������ 0���� ���� 
summary(properties[,46:47])
cor(properties[,c(46:47)],use ="complete.obs")
which(colnames(properties) == "yardbuildingsqft26")
plot(yardbuildingsqft17~logerror,set) #����1�� �����...(87629) ����ȶ�
plot(yardbuildingsqft26~logerror,set) #����1��...(90180) �����/������
properties$yardbuildingsqft17[is.na(properties$yardbuildingsqft17)] <- 0
properties$yardbuildingsqft26[is.na(properties$yardbuildingsqft26)] <- 0


#plot(regionidneighborhood~logerror,set) # (54263) #��κ� �����  -> �ε��� ��ġ������ (�ʿ���������� ���)
#summary(as.factor(properties$regionidneighborhood))

plot(unitcnt~logerror,set) #�Ƕ�̵�...(31922)
plot(numberofstories~logerror,set) #69705, 1,2,3,4�� ����..
plot(lotsizesquarefeet~logerror,set) #�Ƕ�̵� ����(10150) �̽��׸� 
properties$unitcnt[is.na(properties$unitcnt)] <- 0
properties$numberofstories[is.na(properties$numberofstories)] <- 0
properties$lotsizesquarefeet[is.na(properties$lotsizesquarefeet)] <- 0

summary(set[is.na(set$calculatedbathnbr),]$bathroomcnt)
plot(threequarterbathnbr~logerror,set) #(78266),�Ƕ�̵�... �����Ͱ� �������� ���� (����+�����+������) => 1���� ������ ���°� 0 ���� ����
properties$threequarterbathnbr[is.na(properties$threequarterbathnbr)] <- 0
plot(fullbathcnt~logerror,set) # �Ƕ�̵� ���� (1182) => 1165���� ȭ����� ��� ����ġ�� (17���� �پ��)
plot(calculatedbathnbr~logerror, tr) #�Ƕ�̵�� (1182) => 1165���� ȭ����� ��� ����ġ�� (17���� �پ��)
properties$calculatedbathnbr[properties$bathroomcnt==0] <- 0
properties$fullbathcnt[properties$bathroomcnt==0] <- 0

plot(yearbuilt~logerror,set) #756, ������ ���� ������ ����, �������� �׳� �׷�
boxplot(logerror ~ addNA(yearbuilt), set) #�߾Ӱ� ó���� ������
properties$yearbuilt[is.na(properties$yearbuilt)] <- median(properties$yearbuilt, na.rm=T)

#�̳��� �����̶�� ����
plot(taxdelinquencyyear~logerror,set)#�̳� �� ��꼼 ���νñ�: ���Ƕ�̵��(88492) (6~15, 99, ����)
max(properties[properties$taxdelinquencyyear<50,]$taxdelinquencyyear)
properties$taxdelinquencyyear[properties$taxdelinquencyyear>50] <- 0
properties$taxdelinquencyyear[is.na(properties$taxdelinquencyyear)] <- 0

summary(properties)
#99% no match data process
summary(properties[is.na(properties$roomcnt),]) #propertyzoningdesc�� �ִ� �͵�, regionidcounty�� 3101�� �͵��� roomcnt = 0���� ó��
properties <- as.data.frame(properties)
for(i in c(2:which(colnames(properties)=="roomcnt")-1, (which(colnames(properties)=="roomcnt")+1):ncol(properties))) {
  if(is.numeric(properties[,i])) {
    properties[,i][is.na(properties$roomcnt)] <- median(unlist(properties[,i]), na.rm = T)
  }
}

for(i in c(2:which(colnames(properties)=="roomcnt")-1, (which(colnames(properties)=="roomcnt")+1):ncol(properties))) {
  if(is.factor(properties[,i])) {
    properties[,i] <- as.character(properties[,i])
    properties[,i][is.na(properties$roomcnt)] <- "na"  
    properties[,i] <- as.factor(properties[,i])
  }
}
properties$roomcnt[is.na(properties$roomcnt)] <- median(properties$roomcnt, na.rm = T)

#����ġ�� ���� �����ʹ� ���������� ��ü�� (������谡 ���� ������ ����)
cor(as.matrix(subset(set, select = c( taxamount, landtaxvaluedollarcnt, taxvaluedollarcnt, structuretaxvaluedollarcnt))), use = "complete.obs")
plot(calculatedfinishedsquarefeet~logerror,set) #�Ƕ�̵��(661)
plot(structuretaxvaluedollarcnt~logerror,set)#�Ƕ�̵��(380)
plot(taxvaluedollarcnt~logerror,set)#�Ƕ�̵��(1)
plot(landtaxvaluedollarcnt~logerror,set)#�Ƕ�̵��(1)
plot(taxamount~logerror,set) #�Ƕ�̵��.. tax�� ���� ���� �������� ŭ  (6)




library(DMwR)
imp <- knnImputation(subset(properties, select = c(calculatedbathnbr, calculatedfinishedsquarefeet,fullbathcnt,poolsizesum,
                                                   taxamount, landtaxvaluedollarcnt, taxvaluedollarcnt, structuretaxvaluedollarcnt)))



real_set <- merge(train, properties, by="parcelid", all.x = T) 