#ifndef UNI_SIGNAL_PROFILES_MQH
#define UNI_SIGNAL_PROFILES_MQH

// Signal families are independent of numeric scale: RSI and ADX both use
// index values, but their lines do not represent compatible references.
enum ENUM_UNI_SIGNAL_FAMILY
  {
   UNI_SIGNAL_PRICE,
   UNI_SIGNAL_CONSTANT,
   UNI_SIGNAL_RSI,
   UNI_SIGNAL_ADX,
   UNI_SIGNAL_UNSUPPORTED
  };

struct UniSignalProfile
  {
   ENUM_UNI_SIGNAL_FAMILY family;
   bool same_slot;
  };

UniSignalProfile UniSignalProfileForType(const ENUM_GUI_INDICATOR_TYPE type)
  {
   UniSignalProfile profile;
   profile.family=UNI_SIGNAL_UNSUPPORTED; profile.same_slot=false;
   switch(type)
     {
      case GUI_INDICATOR_MA: profile.family=UNI_SIGNAL_PRICE; break;
      case GUI_INDICATOR_RSI: profile.family=UNI_SIGNAL_RSI; profile.same_slot=true; break;
      case GUI_INDICATOR_ADX: profile.family=UNI_SIGNAL_ADX; break;
     }
   return profile;
  }

int UniSignalSourceSlot(const int source)
  {
   if(source>=22 && source<=33) return (source-22)/3;
   if(source>=10 && source<=21) return (source-10)/3;
   return -1;
  }

UniSignalProfile UniSignalSourceProfile(const int source,GuiAppliedConfiguration &config)
  {
   int slot=UniSignalSourceSlot(source);
   if(slot>=0) return UniSignalProfileForType(config.indicators[slot].type);
   UniSignalProfile profile;
   profile.same_slot=false;
   profile.family=source==9 ? UNI_SIGNAL_CONSTANT :
                  (source>=0 && source<=8 ? UNI_SIGNAL_PRICE : UNI_SIGNAL_UNSUPPORTED);
   return profile;
  }

// Call after source/buffer/purpose validation, before accepting a rule.
bool UniSignalSourcesCompatible(const int target,const int reference,GuiAppliedConfiguration &config)
  {
   UniSignalProfile a=UniSignalSourceProfile(target,config);
   UniSignalProfile b=UniSignalSourceProfile(reference,config);
   if(a.family==UNI_SIGNAL_UNSUPPORTED || b.family==UNI_SIGNAL_UNSUPPORTED) return false;
   if(a.family==UNI_SIGNAL_CONSTANT || b.family==UNI_SIGNAL_CONSTANT) return true;
   if(a.family!=b.family) return false;
   return !a.same_slot || UniSignalSourceSlot(target)==UniSignalSourceSlot(reference);
  }

#endif
