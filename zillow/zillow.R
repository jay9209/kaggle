#########################################
# ����: ��������
# ����������: 2017.06.26
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
train <- fread("train_2016_v2.csv",header=T)  #�ŷ��� �ִ� ������ => �ѹ��� �������ΰ� ��� ó��? �������� �ȴ޶���
properties <- fread("properties_2016.csv",header=T)
sub <- fread("sample_submission.csv",header=T)
#str(train)
#str(properties)
#str(sub)
#summary(as.factor(train$transactiondate))
#summary(as.factor(train$parcelid))
#summary(as.factor(properties$parcelid))
#train[train$parcelid=="11842707",]
#properties[properties$parcelid=="11842707",]
#sub[sub$ParcelId=="11842707",]

#length(unique(as.factor(train$parcelid))) #90150 -> logerror�� ���� ����id�� ����, �̴� ������ logerror�� �����ؾ���
#length(unique(as.factor(properties$parcelid))) #2985217
#length(unique(as.factor(sub$ParcelId))) #2985217

str(properties)
#data �÷��� Ÿ�� ��ȯ
properties$rawcensustractandblock <- as.factor(properties$rawcensustractandblock)
properties$censustractandblock <- as.factor(properties$censustractandblock)
properties$regionidzip <- as.factor(properties$regionidzip)
properties$regionidcounty <- as.factor(properties$regionidcounty)
properties$regionidcity <- as.factor(properties$regionidcity) #1803�� ����
#properties$airconditioningtypeid <- as.factor(properties$airconditioningtypeid)
#properties$architecturalstyletypeid <- as.factor(properties$architecturalstyletypeid)
#properties$buildingqualitytypeid <- as.factor(properties$buildingqualitytypeid)
properties$fips <- as.factor(properties$fips)# Federal Information Processing Standard code
#properties$heatingorsystemtypeid <- as.factor(properties$heatingorsystemtypeid)
properties$propertycountylandusecode <- as.factor(properties$propertycountylandusecode) #�ڵ尡 �ʹ� �پ� (1)
properties$propertyzoningdesc <- as.factor(properties$propertyzoningdesc)             # �ڵ尡 �ʹ� �پ�(31962)
properties$propertylandusetypeid <- as.factor(properties$propertylandusetypeid) #���� x
#properties$typeconstructiontypeid <- as.factor(properties$typeconstructiontypeid)

properties$hashottuborspa <- as.factor(properties$hashottuborspa) #���Ŀ���
properties$fireplaceflag <- as.factor(properties$fireplaceflag) 
properties$taxdelinquencyflag <- as.factor(properties$taxdelinquencyflag) 
#���浵 �α׺�ȯ
properties$latitude <- log(properties$latitude)
properties$longitude <- log(abs(properties$longitude))

#�ʿ���� �÷� ����
properties <- subset(properties,select=c(-assessmentyear))
str(properties)
summary(properties$airconditioningtypeid)


#���ϰ��� ������ ���� -> ���ϰ��϶��� log�� ������������, na�϶� Ŀ���� ���� Ȯ���� �� ���� (�� 9����) , �� �� logical�� ���� ����
set <- merge(train, properties, by="parcelid", all.x = T)

boxplot(logerror ~ addNA(storytypeid), set) 
#������ ���� 
boxplot(logerror ~ addNA(pooltypeid2), set) #32075�� ��
boxplot(logerror ~ addNA(pooltypeid10), set) #36941�� ��

boxplot(logerror ~ addNA(poolcnt), set) #�������� 0�̶�� �ǹ̷� ����, ū�ǹ̰� x�� ���� 
boxplot(logerror ~ addNA(pooltypeid7), set) #�ΰ��� �����
#
boxplot(logerror ~ addNA(decktypeid), set)
boxplot(logerror ~ addNA(buildingclasstypeid), set)

set$storytypeid[is.na(set$storytypeid)] <- "na"
set$storytypeid <- as.factor(set$storytypeid)
set$pooltypeid2[is.na(set$pooltypeid2)] <- "na"
set$pooltypeid2 <- as.factor(set$pooltypeid2)
set$pooltypeid10[is.na(set$pooltypeid10)] <- "na"
set$pooltypeid10 <- as.factor(set$pooltypeid10)
set$decktypeid[is.na(set$decktypeid)] <- "na"
set$decktypeid <- as.factor(set$decktypeid)
set$buildingclasstypeid[is.na(set$buildingclasstypeid)] <- "na"
set$buildingclasstypeid <- as.factor(set$buildingclasstypeid)

#������(������ ���� -> ���ο� ����)
boxplot(logerror ~ addNA(hashottuborspa), set) #true or ���� (87910)
boxplot(logerror ~ addNA(fireplaceflag), set) #true 222, ���� 90053
boxplot(logerror ~ addNA(taxdelinquencyflag), set)  #Y 1883, 88492


#�ʿ���� �÷� ����
set <- subset(set,select=c(-poolcnt, -pooltypeid7))
str(set)
#
boxplot(logerror ~ addNA(airconditioningtypeid), set) #�������� 1 Ÿ���� �������� ŭ (61494)
boxplot(logerror ~ addNA(architecturalstyletypeid), set) #������ �ܿ��� ������ �� (90014)
boxplot(logerror ~ addNA(buildingqualitytypeid), set) #1,4,7,10,���� type (32911)
boxplot(logerror ~ addNA(fips), set)  #����x, 3�� ������ ���� 
boxplot(logerror ~ addNA(heatingorsystemtypeid), set) # ����(34195) �پ���
boxplot(logerror ~ addNA(propertylandusetypeid), set) #����x, 14���� 
boxplot(logerror ~ addNA(typeconstructiontypeid), set) #���� 89976 (4,6,13���� 6�� 296 �������� 2,1��..)
#
set$airconditioningtypeid[is.na(set$airconditioningtypeid)] <- "na"
set$airconditioningtypeid <- as.factor(set$airconditioningtypeid)
set$architecturalstyletypeid[is.na(set$architecturalstyletypeid)] <- "na"
set$architecturalstyletypeid <- as.factor(set$architecturalstyletypeid)
set$buildingqualitytypeid[is.na(set$buildingqualitytypeid)] <- "na"
set$buildingqualitytypeid <- as.factor(set$buildingqualitytypeid)
set$heatingorsystemtypeid[is.na(set$heatingorsystemtypeid)] <- "na"
set$heatingorsystemtypeid <- as.factor(set$heatingorsystemtypeid)
set$typeconstructiontypeid[is.na(set$typeconstructiontypeid)] <- "na"
set$typeconstructiontypeid <- as.factor(set$typeconstructiontypeid)


#��ġ�� ����
#�̻� ������ ó�� �ʿ� => �����Ϳ� ���� ���ذ� ������ �Ǿ���. �������� ó���ʿ�

plot(bathroomcnt~logerror,set) #�Ƕ�̵��.. (����x)
plot(bedroomcnt~logerror,set) #�Ƕ�̵�� (����x)

plot(roomcnt~logerror,set) #�� 0���ΰ͸� ������ �پ���, �������� ��� (����x)
summary(set[set$roomcnt == 0 ,]) #���� 0���ΰ� 69700�� (70%): �ְ����� �ִ� ���� �� ������ 
#���� 0���ε� ȭ���, ħ�� ������ ����... ??
#�ش� �ε��꿡 ���� ��� �� ���� �뵵 (���� ����)�� ���� ���� (propertyzoningdesc)
summary(as.factor(as.character(set[set$roomcnt == 0 ,]$propertyzoningdesc)))
summary(as.factor(as.character(set[set$roomcnt > 0 ,]$propertyzoningdesc)))
#LARE40 ���� ���� �ڵ�� 4,000 s.f���� 1 ���� ���� �� �� ������ �ǹ� => �ε��� �����뵵 �ڵ� ���ε� ������ �� ��
#���� ������, roomcnt�� �����ΰ�찡 ���� ����=> ���� �������� 2���� �𵨷� �м��� �����ϴٰ��� ������
set$room_yn <- 0
set$room_yn[set$roomcnt > 0 ] <- 1
set$room_yn <- as.factor(set$room_yn)
boxplot(logerror ~ addNA(room_yn), set)


r0 <- summary(set[set$roomcnt == 0 ,])
r1 <- summary(set[set$roomcnt > 0 ,])
properties
properties[properties$propertyzoningdesc != "" &properties$roomcnt > 0, ] # train, test�� 1���� ���� ����
set[set$propertyzoningdesc != "" &set$roomcnt > 0, ] #�̻����� �Ǵ�
set$propertyzoningdesc[set$propertyzoningdesc != "" & set$roomcnt > 0]  <- ""


for(i in 4:ncol(set)) {
print(colnames(set)[i])
print(data.frame(r0[,i], r1[,i]))
print("---------------------------------")
}

#regionidcounty(�ε�����ġ�� ���� 0 ���ε��� 3101�� �� �ְ�, 3101���� ����)
#typeconstructiontypeid, fireplaceflag �� �� 1�� �̻��� ���� ����
summary(as.factor(properties[properties$roomcnt == 0, ]$typeconstructiontypeid ))
properties$typeconstructiontypeid[properties$roomcnt == 0 & properties$typeconstructiontypeid =="11" ] <- NA
summary(as.factor(properties[properties$roomcnt == 0, ]$fireplaceflag )) #���� �̻󰪿� ���Ե� => ��������
properties$fireplaceflag[properties$roomcnt == 0 & properties$fireplaceflag != "" ] <- ""

summary(properties[is.na(properties$roomcnt),]) #propertyzoningdesc�� �ִ� �͵�, regionidcounty�� 3101�� �͵��� roomcnt = 0���� ó��
#11437���� ���� ��Ī�Ǵ°� ���� 

#�������� ���� ������ �ؾ���
plot(basementsqft~logerror,set) #������ ���� (90232) => ����?
plot(finishedfloor1squarefeet~logerror,set) # ���� 1���� (�����?)- (83419) 

plot(finishedsquarefeet12~logerror,set) #Finished living area �Ƕ�̵��(4679)
plot(finishedsquarefeet13~logerror,set) #Perimeter  living area (90242) #��κ� ����, 1����
plot(finishedsquarefeet15~logerror,set) #Total area             (86711) #��κ� ����, �Ƕ�̵� ����
plot(finishedsquarefeet50~logerror,set) #  Size of the finished living area on the first (entry) floor of the home (83419) #��κ� ���� 1�� �����
plot(finishedsquarefeet6~logerror,set) #Base unfinished and finished area (89854) #��κ� ����, ���� 1��
plot(fireplacecnt~logerror,set) # ��κа���(80668) #�Ƕ�̵� ���� 

#garagecar cnt
boxplot(logerror ~ addNA(garagecarcnt), set) 
plot(garagecarcnt~logerror,set) # ��κа���(60338) #�Ƕ�̵� ���� 
plot(garagetotalsqft~logerror,set) # ��κа���(60338)  #�Ƕ�̵� ����
#
plot(lotsizesquarefeet~logerror,set) #�Ƕ�̵� ����(10150)
plot(poolsizesum~logerror,set) #��κ� ���� (89306) #���� 1��
plot(regionidneighborhood~logerror,set) # (54263) #��κ� ����� 
plot(threequarterbathnbr~logerror,set) #(78266),�Ƕ�̵�... �����Ͱ� �������� ���� 
plot(unitcnt~logerror,set) #�Ƕ�̵�...(31922)
plot(yardbuildingsqft17~logerror,set) #����1�� �����...(87629)
plot(yardbuildingsqft26~logerror,set) #����1��...(90180)
plot(yearbuilt~logerror,set) #756, ������ ���� ������ ����, �������� �׳� �׷�
plot(numberofstories~logerror,set) #69705, 1,2,3,4�� ����..





#����ġ�� ���� �����ʹ� ���������� ��ü�� (������谡 ���� ������ ����)
summary(set[set$bathroomcnt==0,]$calculatedbathnbr)
summary(set[is.na(set$calculatedbathnbr),]$bathroomcnt)
plot(fullbathcnt~logerror,set) # �Ƕ�̵� ���� (1182) => 1165���� ȭ����� ��� ����ġ�� (17���� �پ��)
plot(calculatedbathnbr~logerror, tr) #�Ƕ�̵�� (1182) => 1165���� ȭ����� ��� ����ġ�� (17���� �پ��)
set$calculatedbathnbr[set$bathroomcnt==0] <- 0
set$fullbathcnt[set$bathroomcnt==0] <- 0

plot(calculatedfinishedsquarefeet~logerror,set) #�Ƕ�̵��(661)
plot(structuretaxvaluedollarcnt~logerror,set)#�Ƕ�̵��(380)
plot(taxvaluedollarcnt~logerror,set)#�Ƕ�̵��(1)
plot(landtaxvaluedollarcnt~logerror,set)#�Ƕ�̵��(1)
plot(taxamount~logerror,set) #�Ƕ�̵��.. tax�� ���� ���� �������� ŭ  (6)
set[is.na(set$landtaxvaluedollarcnt),]$taxamount

cor(as.matrix(subset(set, select = c( taxamount, landtaxvaluedollarcnt, taxvaluedollarcnt, structuretaxvaluedollarcnt, 
                                      roomcnt, bedroomcnt, bathroomcnt, calculatedbathnbr, calculatedfinishedsquarefeet
))), use = "complete.obs")


plot(taxdelinquencyyear~logerror,set)#�̳� �� ��꼼 ���νñ�: ���Ƕ�̵��(88492) (6~15, 99, ����)
#�̳��� �ȉ�ٸ� �����̶�� ����
max(set[set$taxdelinquencyyear<50,]$taxdelinquencyyear)
set$taxdelinquencyyear[set$taxdelinquencyyear>50] <- 0
set$taxdelinquencyyear[is.na(set$taxdelinquencyyear)] <- 0