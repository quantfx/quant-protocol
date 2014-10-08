#property indicator_chart_window
//mklink /D Files R:\Files

string ver = "ver.2014.10.08   11:30";

//--- input parameters
input double size = 0.12;

bool test = false;

int real_limit = 10000;
int full_limit = 98000;
int limit;

int DonchianPeriod = 47; //Period of averaging
int MAperiod = 25000;

int LC;
int LC_EURUSD = 24; //24
int LC_USDJPY = 19; //19
int LC_GBPUSD = 26;
int LC_EURJPY = 22;

int Spike;
int Spike_EURUSD = 24; //30
int Spike_USDJPY = 15; //15 /23
int Spike_GBPUSD = 24;
int Spike_EURJPY = 20;
 

double sumDay;
double sumWeek;

int trades;
int days;


int winDays;
int loseDays;


double pip;

double bid0;
double ask0;

MqlTick tick;


string posToday0;
double lossCutToday0;
double entryToday0;
double edgeToday0;

#property indicator_buffers 3
//---- 3 plots are used
#property indicator_plots 3
//+-----------------------------------+
//|  parameters of indicator drawing  |
//+-----------------------------------+
//---- drawing of the indicator as a line
#property indicator_type1 DRAW_NONE
//---- use olive color for the indicator line
#property indicator_color1 LightGreen
//---- indicator line is a solid curve
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width1 1
//---- indicator label display
#property indicator_label1 "Upper Donchian"

//---- drawing of the indicator as a line
#property indicator_type2 DRAW_NONE
//---- use pale violet DeepPink color for the indicator line
#property indicator_color2 Violet
//---- indicator line is a solid curve
#property indicator_style2 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width2 1
//---- indicator label display
#property indicator_label2 "Lower Donchian"


//---- drawing of the indicator as a line
#property indicator_type3 DRAW_LINE
//---- use pale violet DeepPink color for the indicator line
#property indicator_color3 OliveDrab
//---- indicator line is a solid curve
#property indicator_style3 STYLE_SOLID
//---- indicator line width is equal to 1
#property indicator_width3 1
//---- indicator label display
#property indicator_label3 "MA"
//+-----------------------------------+
//|  INPUT PARAMETERS OF THE INDICATOR|
//+-----------------------------------+
//+-----------------------------------+
//---- indicator buffers
double UpperBuffer[];
double LowerBuffer[];
double MABuffer[];
int MA_handle;
//+------------------------------------------------------------------+
//|  searching index of the highest bar                              |
//+------------------------------------------------------------------+
int iHighest(
  const double & array[], // array for searching for maximum element index
    int count, // the number of the array elements (from a current bar to the index descending),
    // along which the searching must be performed.
    int startPos // the initial bar index (shift relative to a current bar),
    // the search for the greatest value begins from
)
{
  //----
  int index = startPos;

  //----checking correctness of the initial index
  if (startPos < 0)
  {
    Print("Bad value in the function iHighest, startPos = ", startPos);
    return (0);
  }
  //---- checking correctness of startPos value
  if (startPos - count < 0)
    count = startPos;

  double max = array[startPos];
  //---- searching for an index
  for (int i = startPos; i > startPos - count; i--)
  {
    if (array[i] > max)
    {
      index = i;
      max = array[i];
    }
  }
  //---- returning of the greatest bar index
  return (index);
}
//+------------------------------------------------------------------+
//|  searching index of the lowest bar                               |
//+------------------------------------------------------------------+
int iLowest(
  const double & array[], // array for searching for minimum element index
    int count, // the number of the array elements (from a current bar to the index descending),
    // along which the searching must be performed.
    int startPos //the initial bar index (shift relative to a current bar),
    // the search for the lowest value begins from
)
{
  //----
  int index = startPos;

  //----checking correctness of the initial index
  if (startPos < 0)
  {
    Print("Bad value in the function iLowest, startPos = ", startPos);
    return (0);
  }

  //---- checking correctness of startPos value
  if (startPos - count < 0)
    count = startPos;

  double min = array[startPos];

  //---- searching for an index
  for (int i = startPos; i > startPos - count; i--)
  {
    if (array[i] < min)
    {
      index = i;
      min = array[i];
    }
  }
  //---- returning of the lowest bar index
  return (index);
}



void OnInit()
{
  if (test)
    limit = full_limit;
  else
    limit = real_limit;

  if (Period() != PERIOD_M1)
  {
    Alert("timeframe must be 1 Min Chart! to trade");
  }

  ObjectsDeleteAll(0, 0, -1);


  if ((Symbol() == "USDJPY") || (Symbol() == "EURJPY"))
  {
    pip = 0.01;
  }
  else
  {
    pip = 0.0001;
  }

  if (Symbol() == "EURUSD")
  {
    LC = LC_EURUSD;
    Spike = Spike_EURUSD;
  }
  if (Symbol() == "USDJPY")
  {
    LC = LC_USDJPY;
    Spike = Spike_USDJPY;
  }
  if (Symbol() == "GBPUSD")
  {
    LC = LC_GBPUSD;
    Spike = Spike_GBPUSD;
  }
  if (Symbol() == "EURJPY")
  {
    LC = LC_EURJPY;
    Spike = Spike_EURJPY;
  }


  ObjectCreate(0, "pair", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "pair", OBJPROP_XDISTANCE, 10);
  ObjectSetInteger(0, "pair", OBJPROP_YDISTANCE, 80);
  //--- set the text
  ObjectSetString(0, "pair", OBJPROP_TEXT, Symbol());
  //--- set text font
  ObjectSetInteger(0, "pair", OBJPROP_FONTSIZE, 15);
  //--- set color
  ObjectSetInteger(0, "pair", OBJPROP_COLOR, clrWhite);

  ObjectCreate(0, "ver", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "ver", OBJPROP_XDISTANCE, 150);
  ObjectSetInteger(0, "ver", OBJPROP_YDISTANCE, 80);
  //--- set the text
  ObjectSetString(0, "ver", OBJPROP_TEXT, ver);
  //--- set text font
  ObjectSetInteger(0, "ver", OBJPROP_FONTSIZE, 10);
  //--- set color
  ObjectSetInteger(0, "ver", OBJPROP_COLOR, clrWhite);



  //---- turning a dynamic array into an indicator buffer
  SetIndexBuffer(0, UpperBuffer, INDICATOR_DATA);
  //---- shifting the start of drawing of the indicator 1
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, DonchianPeriod - 1);
  //--- create label to display in DataWindow
  PlotIndexSetString(0, PLOT_LABEL, "Upper Donchian");
  //---- setting values of the indicator that won't be visible on the chart
  PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);

  //---- turning a dynamic array into an indicator buffer
  SetIndexBuffer(1, LowerBuffer, INDICATOR_DATA);
  //---- shifting the start of drawing of the indicator 3
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, DonchianPeriod - 1);
  //--- create label to display in DataWindow
  PlotIndexSetString(1, PLOT_LABEL, "Lower Donchian");
  //---- setting values of the indicator that won't be visible on the chart
  PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);

  //---- initialization of variable for indicator short name
  string shortname;
  StringConcatenate(shortname, "Donchian( DonchianPeriod = ", DonchianPeriod, ")");
  //--- creation of the name to be displayed in a separate sub-window and in a pop up help
  IndicatorSetString(INDICATOR_SHORTNAME, shortname);
  //--- determination of accuracy of displaying of the indicator values
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);
  //---- end of initialization


  //---- turning a dynamic array into an indicator buffer
  SetIndexBuffer(2, MABuffer, INDICATOR_DATA);
  //---- shifting the start of drawing of the indicator 3
  PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, MAperiod - 1);
  //--- create label to display in DataWindow
  PlotIndexSetString(2, PLOT_LABEL, "MA");
  //---- setting values of the indicator that won't be visible on the chart
  PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);

  MA_handle = iMA(Symbol(), 0, MAperiod, 0, MODE_SMA, PRICE_TYPICAL);

}


int OnCalculate(const int rates_total,
  const int prev_calculated,
    const datetime & time[],
      const double & open[],
        const double & high[],
          const double & low[],
            const double & close[],
              const long & tick_volume[],
                const long & volume[],
                  const int & spread[])
{

  // ObjectsDeleteAll(0, 0, -1);

  int limit1 = prev_calculated;
  if (prev_calculated > 0) limit1--;
  int count = rates_total - limit1;

  if (CopyBuffer(MA_handle, 0, 0, count, MABuffer) < count) return (0);

  SymbolInfoTick(Symbol(), tick);

  if ((tick.bid == bid0) && (tick.ask == ask0))
  {
    return (rates_total);
  }
  else
  {
    bid0 = tick.bid;
    ask0 = tick.ask;
  }

  int i;

  string pos;
  string sign0;
  string sign;

  double entry;
  double edge;

  double ld0;

  double strike;

  string iday0;

  double pips;

  double sumTotal = 0;

  trades = 0;

  days = 0;

  winDays = 0;
  loseDays = 0;

  double lossCut = 999;

  MqlDateTime stm;

  string today = TimeToString(TimeCurrent(), TIME_DATE);

  string tz;

  double dma;

  pos = "flat";
  //--- the main loop of calculations
  for (i = rates_total - limit; i < rates_total; i++)
  {
    //-------------------------------------


    string iday = TimeToString(time[i], TIME_DATE);

    TimeToStruct(time[i], stm);
    int hh = stm.hour;
    int mm = stm.min;

    int date = stm.day;
    ENUM_DAY_OF_WEEK dayofweek = stm.day_of_week;

    int hhmm = hh * 100 + mm;

    //  Print(hhmm);

    if (iday != iday0) // new fx day !!
    {
      iday0 = iday;

      sumDay = 0;
      days++;

      tz = "TK";

      //dma = MABuffer[i] - MABuffer[i - 60*24];

      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);

      ObjectSetInteger(0, "vline" + time[i], OBJPROP_WIDTH, 3);

      ObjectCreate(0, "dt" + time[i], OBJ_TEXT, 0, time[i], close[i] - 5 * pip);
      //--- set the text
      ObjectSetString(0, "dt" + time[i], OBJPROP_TEXT, TimeToString(time[i], TIME_DATE));
      //--- set text font
      ObjectSetInteger(0, "dt" + time[i], OBJPROP_FONTSIZE, 20);
      //--- set color
      ObjectSetInteger(0, "dt" + time[i], OBJPROP_COLOR, clrGray);

      ObjectCreate(0, "dtw" + time[i], OBJ_TEXT, 0, time[i], close[i] - 15 * pip);
      //--- set the text
      ObjectSetString(0, "dtw" + time[i], OBJPROP_TEXT, DayToString(dayofweek));
      //--- set text font
      ObjectSetInteger(0, "dtw" + time[i], OBJPROP_FONTSIZE, 20);
      //--- set color
      ObjectSetInteger(0, "dtw" + time[i], OBJPROP_COLOR, clrGray);

      if (date == 1)
      {
        ObjectCreate(0, "dt1" + time[i], OBJ_TEXT, 0, time[i], close[i] - 35 * pip);
        //--- set the text
        ObjectSetString(0, "dt1" + time[i], OBJPROP_TEXT, "new month, checkout EmploymentNumber date & MT5 demo Account");
        //--- set text font
        ObjectSetInteger(0, "dt1" + time[i], OBJPROP_FONTSIZE, 10);
        //--- set color
        ObjectSetInteger(0, "dt1" + time[i], OBJPROP_COLOR, Orange);
      }

    }


    UpperBuffer[i] = high[iHighest(high, DonchianPeriod, i)];
    LowerBuffer[i] = low[iLowest(low, DonchianPeriod, i)];

    double D = (UpperBuffer[i] - LowerBuffer[i]) / pip;

    double L = LowerBuffer[i] + (UpperBuffer[i] - LowerBuffer[i]) * 0.1;

    double U = UpperBuffer[i] - (UpperBuffer[i] - LowerBuffer[i]) * 0.1;


    if (hhmm == 0900)
    {
      ld0 = open[i];
      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);

    }

    //===== sign0 stream ====================================================

    if ((mm == 00) || (mm == 30))
    {
      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);
    }

    if (D >= Spike)
    {
      if( MABuffer[i]>open[i] )
      if (dma < 0)
        if (open[i] > U)
        {
          if (pos == "flat")
            sign0 = "short";

          if (pos == "long")
            sign = "flat";
        }
      if( MABuffer[i]<open[i] )
      if (dma > 0)
        if (open[i] < L)
        {
          if (pos == "flat")
            sign0 = "long";

          if (pos == "short")
            sign = "flat";
        }
    }


    //----------

    if (hhmm == 0935)
    {

      tz = "LD";
      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);

    }

    if ((hhmm == 0935))
    {

      double d0 = open[i] - ld0;
      double d1 = open[i] - open[i - 20];

      double d01;
      if (MathAbs(d0) > MathAbs(d1))
        d01 = d0;
      else
        d01 = d1;

      if (pos == "flat")
      {
        if( MABuffer[i]>open[i] )
        if (dma < 0)
          sign0 = "short";
          
        if( MABuffer[i]<open[i] ) 
        if (dma > 0)
          sign0 = "long";
      }

    }

    if (hhmm == 1500)
    {
      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);
      tz = "NY";
    }

    if ((hhmm == 1545))
    {

      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);
    }


    if ((hhmm == 1615))
    {

      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);
    }

    if ((hhmm == 1630))
    {

      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);
    }

    if (hhmm == 1700)
    {
      tz = "NY2";
      ObjectCreate(0, "vline" + time[i], OBJ_VLINE, 0, time[i], 0);
      ObjectSetInteger(0, "vline" + time[i], OBJPROP_COLOR, clrGray);
    }
    //  if (pos == "flat")



    if ((hhmm >= 2000))
    {
      tz = "NY3";
    }

    if (hhmm >= 2300)
    {
      if (dayofweek == 5)
      {
        sign = "flat"; // must be directly to sign not sign0
        sign0 = "flat";
        strike = open[i];
         
        dma = MABuffer[i] - MABuffer[i - 60*24*5];
      }
    }


    if (hhmm == 2305)
    {
      showPipsDay(time[i - 50], close[i], sumDay);

    }

    //=====================================================================

    //sign stream =========================

    double d = open[i] - open[i - 6];

    //-----------

    if ((sign0 == "long") && (d > 0))
    {
      sign = "long";

      strike = open[i];
    }

    if ((sign0 == "short") && (d < 0))
    {
      sign = "short";

      strike = open[i];
    }

    //------------



    //===============================



    //losscut stream =========================

    if (pos == "long")
    {

      if (high[i - 1] > edge)
        edge = high[i - 1];

      double lcT = edge - LC * pip;

      lossCut = NormalizeDouble(lcT, 5);

      ObjectCreate(0, "taglc" + time[i], OBJ_TREND, 0, time[i], lossCut, time[i - 1], lossCut);
      //--- set text font
      ObjectSetInteger(0, "taglc" + time[i], OBJPROP_WIDTH, 2);
      //--- set color
      ObjectSetInteger(0, "taglc" + time[i], OBJPROP_COLOR, clrDeepPink);


      //----losscut hit

      if (low[i] <= lossCut)
      {
        sign = "flat";
        
        strike = lossCut;

        lossCut = 999;
      }


    }

    if (pos == "short")
    {

      if (low[i - 1] < edge)
        edge = low[i - 1];

      double lcT = edge + LC * pip;

      lossCut = NormalizeDouble(lcT, 5);

      ObjectCreate(0, "taglc" + time[i], OBJ_TREND, 0, time[i], lossCut, time[i - 1], lossCut);
      //--- set text font
      ObjectSetInteger(0, "taglc" + time[i - 1], OBJPROP_WIDTH, 2);
      //--- set color
      ObjectSetInteger(0, "taglc" + time[i - 1], OBJPROP_COLOR, clrAqua);


      //----losscut hit

      if (high[i] >= lossCut)
      {
        
        sign = "flat";  

        strike = lossCut;

        lossCut = 999;
      }

    }

    //==========================


    //!!!!!!!!!!!!!!!!!!!!!!!!!


    //position stream =========================

    if (pos != sign)
    {
      if (sign == "flat")
      {

        pos = sign;
        sign0 = "flat";

        if (entry != 0)
        {
          string side;
          if (edge > open[i]) //long
          {
            pips = (strike - entry) / pip;
            side = "L";
          }
          else
          {
            pips = (entry - strike) / pip;
            side = "S";
          }

          sumTotal = showPips(time[i], strike, pips, side, sumTotal);

          entry = 0;
          lossCut = 999;

          ObjectCreate(0, "tagstop" + time[i], OBJ_ARROW_LEFT_PRICE, 0, time[i], strike);
          //--- set text font
          ObjectSetInteger(0, "tagstop" + time[i], OBJPROP_WIDTH, 3);
          //--- set color
          ObjectSetInteger(0, "tagstop" + time[i], OBJPROP_COLOR, clrWhite);

          ObjectCreate(0, "taglc" + time[i], OBJ_TREND, 0, time[i], lossCut, time[i - 1], lossCut);
          //--- set text font
          ObjectSetInteger(0, "taglc" + time[i], OBJPROP_WIDTH, 2);
          //--- set color
          ObjectSetInteger(0, "taglc" + time[i], OBJPROP_COLOR, clrAqua);
        }

      }

      else  
      {
        if (sign == "long")
        {
          pos = sign;

          sign0 = "flat";

          if (entry != 0)
          {
            pips = (entry - strike) / pip;
            sumTotal = showPips(time[i], strike, pips, "S", sumTotal);
          }

          entry = strike;
          lossCut = NormalizeDouble(entry - LC * pip, 5);

          edge = entry;

          ObjectCreate(0, "tag" + time[i], OBJ_ARROW_LEFT_PRICE, 0, time[i], strike);
          //--- set text font
          ObjectSetInteger(0, "tag" + time[i], OBJPROP_WIDTH, 3);
          //--- set color
          ObjectSetInteger(0, "tag" + time[i], OBJPROP_COLOR, clrAqua);

        }
        if (sign == "short")
        {
          pos = sign;
  
          sign0 = "flat";

          if (entry != 0)
          {
            pips = (strike - entry) / pip;
            sumTotal = showPips(time[i], strike, pips, "L", sumTotal);
          }

          entry = strike;
          lossCut = NormalizeDouble(entry + LC * pip, 5);

          edge = entry;

          ObjectCreate(0, "tag" + time[i], OBJ_ARROW_LEFT_PRICE, 0, time[i], strike);
          //--- set text font
          ObjectSetInteger(0, "tag" + time[i], OBJPROP_WIDTH, 3);
          //--- set color
          ObjectSetInteger(0, "tag" + time[i], OBJPROP_COLOR, clrDeepPink);

          ObjectCreate(0, "taglc" + time[i], OBJ_TREND, 0, time[i], lossCut, time[i - 1], lossCut);
          //--- set text font
          ObjectSetInteger(0, "taglc" + time[i], OBJPROP_WIDTH, 2);
          //--- set color
          ObjectSetInteger(0, "taglc" + time[i], OBJPROP_COLOR, clrAqua);


        }
      }
    }


    //!!!!!!!!!!!!!!!!!!!!!!!!!!


    //--------------------------------------------
  }

  //latest result -------------




  datetime current = TimeCurrent();
  string dt = TimeToString(current, TIME_DATE) + "   " + TimeToString(current, TIME_SECONDS);

  ObjectCreate(0, "dt", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "dt", OBJPROP_XDISTANCE, 10);
  ObjectSetInteger(0, "dt", OBJPROP_YDISTANCE, 100);
  //--- set the text
  ObjectSetString(0, "dt", OBJPROP_TEXT, dt);
  //--- set text font
  ObjectSetInteger(0, "dt", OBJPROP_FONTSIZE, 15);
  //--- set color
  ObjectSetInteger(0, "dt", OBJPROP_COLOR, clrWhite);



  ObjectCreate(0, "pos", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "pos", OBJPROP_XDISTANCE, 10);
  ObjectSetInteger(0, "pos", OBJPROP_YDISTANCE, 120);
  //--- set the text
  ObjectSetString(0, "pos", OBJPROP_TEXT, pos);
  //--- set text font
  ObjectSetInteger(0, "pos", OBJPROP_FONTSIZE, 15);
  //--- set color
  if (pos == "long")
    ObjectSetInteger(0, "pos", OBJPROP_COLOR, clrAqua);
  else if (pos == "short")
    ObjectSetInteger(0, "pos", OBJPROP_COLOR, clrDeepPink);
  else
    ObjectSetInteger(0, "pos", OBJPROP_COLOR, clrWhite);

  ObjectCreate(0, "lc", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "lc", OBJPROP_XDISTANCE, 10);
  ObjectSetInteger(0, "lc", OBJPROP_YDISTANCE, 140);
  //--- set the text
  ObjectSetString(0, "lc", OBJPROP_TEXT, lossCut);
  //--- set text font
  ObjectSetInteger(0, "lc", OBJPROP_FONTSIZE, 15);
  //--- set color
  ObjectSetInteger(0, "lc", OBJPROP_COLOR, clrWhite);


  ObjectCreate(0, "size", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "size", OBJPROP_XDISTANCE, 110);
  ObjectSetInteger(0, "size", OBJPROP_YDISTANCE, 125);
  //--- set the text
  ObjectSetString(0, "size", OBJPROP_TEXT, size);
  //--- set text font
  ObjectSetInteger(0, "size", OBJPROP_FONTSIZE, 20);
  //--- set color
  ObjectSetInteger(0, "size", OBJPROP_COLOR, clrOrange);

  if (test)
  {
    double pipsT = MathRound(sumTotal * 10) / 10;

    ObjectCreate(0, "sumtotal", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "sumtotal", OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, "sumtotal", OBJPROP_YDISTANCE, 200);
    //--- set the text
    ObjectSetString(0, "sumtotal", OBJPROP_TEXT, DoubleToString(pipsT, 1) + " pips");
    //--- set text font
    ObjectSetInteger(0, "sumtotal", OBJPROP_FONTSIZE, 10);
    //--- set color
    ObjectSetInteger(0, "sumtotal", OBJPROP_COLOR, clrWhite);


    ObjectCreate(0, "trades", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "trades", OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, "trades", OBJPROP_YDISTANCE, 213);
    //--- set the text
    ObjectSetString(0, "trades", OBJPROP_TEXT, trades + " trades " + days + " days");
    //--- set text font
    ObjectSetInteger(0, "trades", OBJPROP_FONTSIZE, 10);
    //--- set color
    ObjectSetInteger(0, "trades", OBJPROP_COLOR, clrWhite);

    ObjectCreate(0, "winloserate", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "winloserate", OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, "winloserate", OBJPROP_YDISTANCE, 225);
    //--- set the text

    double winDayRate = winDays / days;
    ObjectSetString(0, "winloserate", OBJPROP_TEXT, winDays + " : " + loseDays + " " + winDayRate);
    //--- set text font
    ObjectSetInteger(0, "winloserate", OBJPROP_FONTSIZE, 10);
    //--- set color
    ObjectSetInteger(0, "winloserate", OBJPROP_COLOR, clrWhite);
  }
  ObjectCreate(0, "rt", OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, "rt", OBJPROP_XDISTANCE, 200);
  ObjectSetInteger(0, "rt", OBJPROP_YDISTANCE, 0);

  //--- set text font
  ObjectSetInteger(0, "rt", OBJPROP_FONTSIZE, 15);

  if ((Period() == PERIOD_M1) && (!test))
  {
    //--- set the text
    ObjectSetString(0, "rt", OBJPROP_TEXT, "Realtime");
    //--- set color
    ObjectSetInteger(0, "rt", OBJPROP_COLOR, clrGreen);

    //--- open the file
    ResetLastError();

    int file_handle = FileOpen(Symbol() + ".txt", FILE_READ | FILE_WRITE | FILE_TXT);

    if (file_handle != INVALID_HANDLE)
    {
      FileWrite(file_handle, dt);
      FileWrite(file_handle, pos);
      FileWrite(file_handle, lossCut);
      FileWrite(file_handle, size);
      FileWrite(file_handle, LC);
      //--- close the file
      FileClose(file_handle);
    }
    else
      Print("Failed to open the file");
  }
  else
  {
    //--- set the text
    ObjectSetString(0, "rt", OBJPROP_TEXT, "Historical Logout!");
    //--- set color
    ObjectSetInteger(0, "rt", OBJPROP_COLOR, clrBrown);
  }

  //----------------------------

  //--- OnCalculate done. Return new prev_calculated.
  return (rates_total);
}
//+------------------------------------------------------------------+

double showPips(datetime timei, double closei, double pips, string side, double sumTotal)
{
  if (MathAbs(pips) > 5000)
    pips = 0;

  double pips1 = MathRound(pips * 10) / 10;

  sumDay += pips1;
  sumWeek += pips1;
  sumTotal += pips1;

  trades++;

  int d;
  if (side == "L")
    d = 1;
  else
    d = -1;

  ObjectCreate(0, "pips" + timei, OBJ_TEXT, 0, timei, closei + 5 * pip * d);
  //--- set the text
  ObjectSetString(0, "pips" + timei, OBJPROP_TEXT, DoubleToString(pips1, 1));
  //--- set text font
  ObjectSetInteger(0, "pips" + timei, OBJPROP_FONTSIZE, 26);
  //--- set color
  ObjectSetInteger(0, "pips" + timei, OBJPROP_COLOR, clrWheat);

  return sumTotal;
}

void showPipsDay(datetime timei, double closei, double pips)
{
  double pips1 = MathRound(pips * 10) / 10;

  if (pips > 0) winDays++;
  else loseDays++;

  ObjectCreate(0, "pipsD" + timei, OBJ_TEXT, 0, timei, closei + 20 * pip);
  //--- set the text
  ObjectSetString(0, "pipsD" + timei, OBJPROP_TEXT, DoubleToString(pips1, 1));
  //--- set text font
  ObjectSetInteger(0, "pipsD" + timei, OBJPROP_FONTSIZE, 33);
  //--- set color
  ObjectSetInteger(0, "pipsD" + timei, OBJPROP_COLOR, clrGray);
}


void showPipsWeek(datetime timei, double closei, double pips)
{
  double pips1 = MathRound(pips * 10) / 10;


  ObjectCreate(0, "pipsW" + timei, OBJ_TEXT, 0, timei, closei - 20 * pip);
  //--- set the text
  ObjectSetString(0, "pipsW" + timei, OBJPROP_TEXT, DoubleToString(pips1, 1));
  //--- set text font
  ObjectSetInteger(0, "pipsW" + timei, OBJPROP_FONTSIZE, 50);
  //--- set color
  ObjectSetInteger(0, "pipsW" + timei, OBJPROP_COLOR, clrWhite);
}

void OnDeinit(const int reason)
{ 
  ObjectsDeleteAll(0, 0, -1);
  IndicatorRelease(MA_handle);
}
 

string DayToString(ENUM_DAY_OF_WEEK day)
{
  switch (day)
  {
    case SUNDAY:
      return "Sunday";
    case MONDAY:
      return "Monday";
    case TUESDAY:
      return "Tuesday";
    case WEDNESDAY:
      return "Wednesday";
    case THURSDAY:
      return "Thursday";
    case FRIDAY:
      return "Friday";
    case SATURDAY:
      return "Saturday";
    default:
      return "Unknown day of week";
  }
  return "";
}