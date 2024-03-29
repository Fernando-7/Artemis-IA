//+------------------------------------------------------------------+
//|                                                Fibo_Revisado.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Expert variáveis globais                                         |
//+------------------------------------------------------------------+
int tendencia = -1, analisar = 0, HeightAtual=0, tipo = -1, ordensAbertas = 0;
double MaxValue, MinValue, RefValue, ordem[2][2];
//double extern fibo = 0.236;
//int extern Height, acrescimo = 5;

// valor mínimo que indica sobrevenda
extern int mfibuy; 
// valor maximo que indica sobre compra
extern int mfisell; 

extern double step;
extern double maximo;
extern int   psar_cont;

extern double osma;

// refere-se ao parâmetro período que também está no indicador MACD (peça chave para indicação de compra e venda)
extern int signal_osma;

// período referente a quatidade de barras da média móvel do OsMA 
extern int period_osma; 

 // referese ao período da média movel do indicador IFR

int confirm; // variavel para ajudar caso tenha que abrir uma ordem na proxima reversão do psar
//variaveis que auxiliamno take e no stop

 // variavel que recebe do usuario o valor do tamanho do stoploss em inteiro ex: 17
extern int stoploss;

// variavel que recebe do usuario o valor do tamanho do takeproft em inteiro ex: 17
extern int take; 

int special_type;
double stopPoint;
double takePoint;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
  
  // if(stoploss < MarketInfo(Symbol(),MODE_STOPLEVEL))
  //    stoploss = MarketInfo(Symbol(),MODE_STOPLEVEL;
  tendencia = 2; 
  confirm = 0;
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }

//+------------------------------------------------------------------+
//| Expert PSAR function                                             |
//+------------------------------------------------------------------+  


int FractalPsar(){
   double PSARCurrent=iSAR(NULL,PERIOD_M1,step,maximo,1);
   double PSARCurrent5=iSAR(NULL,PERIOD_M5,step,maximo,1);
   double PSARCurrent15=iSAR(NULL,PERIOD_M15,step,maximo,1);
   
   if( (PSARCurrent < iLow(NULL,PERIOD_M1,1))&& 
   (PSARCurrent5 < iLow(NULL,PERIOD_M5,1)) &&
    (PSARCurrent15 > iHigh(NULL,PERIOD_M15,1))){
         
            return(0); 
         
        }else if( (PSARCurrent > iHigh(NULL,PERIOD_M1,1)) &&
               PSARCurrent5 > iHigh(NULL,PERIOD_M5,1) &&
               PSARCurrent15 < iLow(NULL,PERIOD_M15,1)){
        
            return(1); 
        }

        return(-1);

}



//+------------------------------------------------------------------+
//| StopLoss en TakeProft Mode                                                    |
//+------------------------------------------------------------------+

void monitoringStopTake(){ // monitora os valores de ask e bis para uma ordem em função de saber se atingiu o takeproft ou o stoploss desejado
  // Print("Stop ",stopPoint," Take ",takePoint," Bid ",Bid,"VALOR", special_type);
   if((Ask >= stopPoint && special_type == 1) || (Ask <= takePoint && special_type == 1)){
      fecharOrdem(special_type);
   }if((Bid <= stopPoint && special_type == 0) || (Bid >= takePoint && special_type == 0)){
      fecharOrdem(special_type);
   }   
}

void getTakeStop(int type){ //estabelece o takeproft e o stoploss para uma ordem
   special_type = type;
   
   if(type == 0){
      
      takePoint = NormalizeDouble((Bid + (Point * take)),Digits);
      stopPoint = NormalizeDouble(Bid - (Point * stoploss),Digits);
      
   }else{
      
      takePoint = NormalizeDouble((Ask - (Point * take)),Digits);
      stopPoint = NormalizeDouble(Ask + (Point * stoploss),Digits);
   }
}
//+------------------------------------------------------------------+
//| Expert MFI function                                              |
//+------------------------------------------------------------------+


int getMfi(){ // retorna a indicação de sobrecompra ou sobrevenda do mfi
   if(iMFI(NULL,PERIOD_M1,14,0) >= mfisell){ //venda
    
         return 1;
   
   }else if(iMFI(NULL,PERIOD_M1,14,0) <= mfibuy){ //compra
   
         return 0;
   }
   
   return -1;
}


//+------------------------------------------------------------------+
//| Expert abrirOrdem function                                       |
//+------------------------------------------------------------------+

void abrirOrdem(int type){
   int tick;
   double price[2];
   price[0]=Ask;
   price[1]=Bid;
   if(type!=-1){   
   
      tick = OrderSend(Symbol(),type,1,price[type],0,0.0,0.0,"Ordem Fibo",100,0,clrDarkRed);
      getTakeStop(type); // estabelece o take e o stop
     
      if(tick>0){
         ordem[type][0]=tick;
         ordem[type][1]=price[type];
       
      }else{
          Alert ("Erro ao Tentar abrir uma ordem");   
      }
   }
}

//+------------------------------------------------------------------+
//| Expert fecharOrdem function                                      |
//+------------------------------------------------------------------+  

void fecharOrdem(int type){
    
   double price[2];
   price[0]=Ask;
   price[1]=Bid;
   if((OrdersTotal()!=0)&&(ordem[type][0]!=-1)){
      if(!OrderClose((int)ordem[type][0], 1.0, price[1-type], 0, clrWhite)){
      
         Alert ("Erro ao Tentar fechar uma ordem");   
      }
      else{
         ordem[type][0]=-1;
         ordem[type][1]=0;
         ordensAbertas=0;
         analisar=0;
         
          
      }   
   }
}

//+------------------------------------------------------------------+
//| Expert analise function                                          |
//+------------------------------------------------------------------+  


void Analise2x(){ //PROXIMO PASSO
   
   if(OrdersTotal() == 0){
   
      if(getMfi() == 0  && confirm != -1){ //compra
           
         if(FractalPsar() == 1 ){
            abrirOrdem(1);
         }else{
            confirm = -1;
         }
          
      }else if(getMfi() == 1  && confirm != -1){ //venda
            
         if(FractalPsar() == 0 ){
            abrirOrdem(0);
         }else{
            confirm = -1;
         }
         
      }else if(confirm == -1 && FractalPsar() != -1){
         abrirOrdem(confirm);
         confirm = 0;
     }
   }

}
 

//+------------------------------------------------------------------+
//| Expert monitorar function                                        |
//+------------------------------------------------------------------+
  

  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(OrdersTotal() == 0){
      Analise2x();
   }else{
      monitoringStopTake();
   }   
  }
//+------------------------------------------------------------------+