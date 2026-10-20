#property strict
// Production EA unchanged; this wrapper only exports the actual visual buffers.
#include "../UniEA.mq5"
double OnTester()
  {
   if(!MQLInfoInteger(MQL_TESTER)) return 0;
   string file=StringFormat("HistogramAudit_%I64d.csv",InpMagic);
   int out=FileOpen(file,FILE_CSV|FILE_WRITE|FILE_ANSI,',',CP_UTF8);
   if(out==INVALID_HANDLE) { Print("HistogramAudit: cannot open output ",GetLastError()); return 0; }
   FileWrite(out,"slot","time","height","color","state"); int written=0,unavailable=0;
   datetime times[]; int count=CopyTime(_Symbol,_Period,0,InpHistogramasBarras,times);
   for(int w=1;w<(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);w++)
      for(int i=0;i<ChartIndicatorsTotal(0,w);i++)
        {
         string name=ChartIndicatorName(0,w,i); if(StringFind(name,"UNI S ")!=0) continue;
         int marker=StringFind(name,"| "); int slot=(int)StringToInteger(StringSubstr(name,marker+2,1));
         int handle=ChartIndicatorGet(0,w,name); double heights[],palette[];
         if(handle==INVALID_HANDLE || CopyBuffer(handle,0,0,count,heights)!=count || CopyBuffer(handle,1,0,count,palette)!=count)
           { Print("HistogramAudit: buffer read failed ",name," ",GetLastError()); if(handle!=INVALID_HANDLE) IndicatorRelease(handle); continue; }
         for(int b=0;b<count;b++)
           {
            int state=heights[b]==EMPTY_VALUE ? 2 : palette[b]==0 ? 1 : palette[b]==1 ? -1 : 0;
            FileWrite(out,slot,TimeToString(times[b],TIME_DATE|TIME_SECONDS),heights[b],palette[b],state);
            written++; if(state==2) unavailable++;
           }
         IndicatorRelease(handle);
        }
   FileClose(out); PrintFormat("[HistogramVisualAudit] rows=%d unavailable=%d file=%s",written,unavailable,file);
   return 0;
  }
