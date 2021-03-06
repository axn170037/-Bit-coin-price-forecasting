# 3.6.5 According to mu model, all the others have signficance effect on bitcoin but gold has no impact or significance on the bitcoin prices.
# 3.6.6 Bitcoin: Diff:1 Level   
# WTI: Diff:1 Level  
# GOLD: Diff:1 Level 
# SP500: Diff:1 Level   
# US Euro: Diff:1 Trend
# 3.6.7 After differences it shows that nothing is significant.
# 3.6.10 model33 <- arima(log(df1$bvalue),c(11,1,11)). p-11,q-11,d-1.
# 3.6.12 No.
#install.packages('plyr')
library(plyr)
# 3.6

library(data.table)
library(dplyr)
library(DBI)
library(tseries)
library(TSA)
library(vars)
library(ggplot2)
library(gtable)
library(grid)
library(forecast)

sp500<- read.csv('SP500.csv', na.strings = "#N/A")
wti<- read.csv('West Texas Intermediate.csv',na.strings = "#N/A")
bitcoin<- read.csv('Bitcoin.csv',na.strings = "#N/A")
gold<- read.csv('GOLDAMGBD228NLBM.csv',na.strings = "#N/A")
useuro<- read.csv('US-EURO Exchange rate.csv',na.strings = "#N/A")

combined<- list(sp500,wti,bitcoin,gold,useuro)
bitcoin<- join_all(combined,by= "Date", type="inner")
bitcoin$Date <- as.Date(bitcoin$Date, "%Y-%m-%d")
bitcoin$SP500<-as.numeric(bitcoin$SP500)
bitcoin$crudepr<-as.numeric(bitcoin$crudepr)
bitcoin$bvalue<-as.numeric(bitcoin$bvalue)
bitcoin$GOLD<-as.numeric(bitcoin$GOLD)
bitcoin$deusconv<-as.numeric(bitcoin$deusconv)


summary(bitcoin)

head(bitcoin)

bitcoin$date <- as.Date(bitcoin$date)

p1 <- ggplot(bitcoin,aes(x=date,y=bitcoin)) + geom_line() 
p2 <- ggplot(bitcoin,aes(x=date,y=sp500)) + geom_line()
p3 <- ggplot(bitcoin,aes(x=date,y=gold)) + geom_line()
p4 <- ggplot(bitcoin,aes(x=date,y=oil)) + geom_line()
p5 <- ggplot(bitcoin,aes(x=date,y=euro)) + geom_line()
g1 <- ggplotGrob(p1)
g2 <- ggplotGrob(p2)
g3 <- ggplotGrob(p3)
g4 <- ggplotGrob(p4)
g5 <- ggplotGrob(p5)
g <- rbind(g1, g2, g3, g4, g5, size = "first")
g$widths <- unit.pmax(g1$widths, g2$widths, g3$widths, g4$widths, g5$widths)
grid.newpage()
grid.draw(g)

summary(lm(bitcoin~sp500+gold+oil+euro,data=bitcoin))

rep.kpss <- function(series,alpha=0.05,dmax=5){
  diff <- 0
  for(i in 1:dmax){
    suppressWarnings(pval <- kpss.test(series,null="Level")$p.value)
    if(pval>=alpha){
      return(c(diff,0,pval))
    }
    suppressWarnings(pval <- kpss.test(series,null="Trend")$p.value)
    if(pval>=alpha){
      return(c(diff,1,pval))
    }
    diff <- diff + 1
    series <- diff(series)
  }
  return(NULL)
}

rep.kpss(bitcoin$bitcoin)
rep.kpss(bitcoin$sp500)
rep.kpss(bitcoin$gold)
rep.kpss(bitcoin$oil)
rep.kpss(bitcoin$euro)

n <- nrow(bitcoin)
summary(lm(diff(bitcoin)~diff(sp500)+diff(gold)+diff(oil)+diff(euro)+as.numeric(date)[2:n],data=bitcoin))

model0 <- lm(diff(bitcoin)~diff(sp500)+diff(gold)+diff(oil)+diff(euro)+as.numeric(date)[2:n],data=bitcoin)
coeftest(model0,vcov=NeweyWest(model0,lag=10))

bitcoin <- bitcoin[date>=as.Date('2017-01-01')]

p1 <- ggplot(bitcoin,aes(x=date,y=bitcoin)) + geom_line() 
p2 <- ggplot(bitcoin,aes(x=date,y=sp500)) + geom_line()
p3 <- ggplot(bitcoin,aes(x=date,y=gold)) + geom_line()
p4 <- ggplot(bitcoin,aes(x=date,y=oil)) + geom_line()
p5 <- ggplot(bitcoin,aes(x=date,y=euro)) + geom_line()
g1 <- ggplotGrob(p1)
g2 <- ggplotGrob(p2)
g3 <- ggplotGrob(p3)
g4 <- ggplotGrob(p4)
g5 <- ggplotGrob(p5)
g <- rbind(g1, g2, g3, g4, g5, size = "first")
g$widths <- unit.pmax(g1$widths, g2$widths, g3$widths, g4$widths, g5$widths)
grid.newpage()
grid.draw(g)

acf(diff(bitcoin$bitcoin))
acf(diff(bitcoin$sp500))
acf(diff(bitcoin$gold))
acf(diff(bitcoin$oil))
acf(diff(bitcoin$euro))

pacf(diff(bitcoin$bitcoin))
pacf(diff(bitcoin$sp500))
pacf(diff(bitcoin$gold))
pacf(diff(bitcoin$oil))
pacf(diff(bitcoin$euro))

auto.arima(bitcoin$bitcoin,d=1,max.p=10,max.q=10)

model1 <- stats::arima(bitcoin$bitcoin, c(0,1,0))
forec1 <- forecast(model1,h=30)
plot(forec1)

periodogram(diff(bitcoin$bitcoin))

bitcoin$weekday <- as.factor(weekdays(bitcoin$date))

n <- nrow(bitcoin)
summary(lm(diff(bitcoin)~weekday[2:n],data=bitcoin))
bitcoin$res[2:n] <- residuals(lm(diff(bitcoin)~weekday[2:n],data=bitcoin))

periodogram(bitcoin$res[2:n])

diff_jp <- function(x){
  n <- nrow(x)
  return(x[2:n,]-x[1:n-1,])
}
x <- bitcoin %>% dplyr::select(bitcoin,sp500,gold,oil,euro) %>% diff_jp
VAR(x,p=1,type="both") %>% AIC
VAR(x,p=2,type="both") %>% AIC
VAR(x,p=3,type="both") %>% AIC
VAR(x,p=4,type="both") %>% AIC
VAR(x,p=5,type="both") %>% AIC

model2 <- VAR(x,p=2,type="both")
library(broom)
summary(model2)

n <- nrow(bitcoin)
forec2 <- predict(model2,n.ahead=30)$fcst$bitcoin
forec2 <- forec2[,1]
forec2 <- bitcoin$bitcoin[n] + cumsum(forec2)
cbind(forec1$mean,forec2)

bitcoin$bitcoin[n]+cumsum(predict(model2,n.ahead=30)$fcst$bitcoin[,1])
