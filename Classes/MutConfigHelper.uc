/*
 * this class wraps the event listeners and provides additional context information so that multiple controls can use the same handler
 */

class MutConfigHelper extends Actor;


struct SliderEventData
{
  var GfxClikWidget.EventData EventData;
  var string Label;
  var float Value;
};

struct SliderMapping
{
  var string sliderName;
  var delegate<SliderEventListener> listener;
  var string label;
  var CRZSliderWidget slider;
};

struct CheckboxMapping
{
  var string name;
  var delegate<CheckBoxEventListener> listener;
  var string label;
};

struct ObjectDictEntry
{
  var string key;
  var object val;
};

struct StringDictEntry
{
  var string key;
  var string val;
};

var private class clazz;
var private array<SliderMapping> sliders;
var private array<CheckboxMapping> checkboxes;
var private array<ObjectDictEntry> objectDict;
var private array<StringDictEntry> stringDict;
var private delegate<TimerFunc> timerHandler;

static delegate SliderEventListener(string label, float value, GFxClikWidget.EventData data);
static delegate CheckBoxEventListener(string label, bool value, GFxClikWidget.EventData data);
static delegate TimerFunc();


function PostBeginPlay()
{
  super.PostBeginPlay();
  SetTickGroup(TG_PreAsyncWork);
}

public static function NotifyPopulated(class classRef)
{  
  local MutConfigHelper helper;
  helper = GetHelper();
  helper.clazz = classRef;
  helper.sliders.Length = 0;
  helper.checkboxes.Length = 0;
  helper.stringDict.Length = 0;
  helper.objectDict.Length = 0;
}

public static function MutConfigHelper GetHelper()
{
  local WorldInfo world;
  local MutConfigHelper helper;
  
  world = class'WorldInfo'.static.GetWorldInfo();
  foreach world.AllActors(class'MutConfigHelper', helper)
    return helper;

  return world.Spawn(class'MutConfigHelper');
}

public static function CRZSliderWidget AddSlider(GFxCRZFrontEnd_ModularView ConfigView, string label, string descr, float min, float max, float snap, float val, delegate<SliderEventListener> listener, optional GfxObject dataProvider)
{
  local CRZSliderWidget slider; 
  local MutConfigHelper helper;

  slider = ConfigView.AddSlider(ConfigView.ListObject1, "CRZSlider", label, descr);
  
  helper = GetHelper();
  helper.AddSliderToList(slider, label, min, max, snap, val, listener, dataProvider);
  return Slider;
}

public function SetSliderValue(string label, float value)
{
	local int i;
	for (i=0; i<sliders.Length; i++)
	{
		if (sliders[i].label != label)
			continue;
		sliders[i].slider.SetFloat("value", value);
		break;
	}
}

private function AddSliderToList(CRZSliderWidget slider, string label, float min, float max, float snap, float val, delegate<SliderEventListener> listener, GfxObject dataProvider)
{
  Sliders.Add(1);
  Sliders[Sliders.Length-1].SliderName = slider.GetString("_name");
  Sliders[Sliders.Length-1].Label = label;
  Sliders[Sliders.Length-1].Listener = listener;
  Sliders[Sliders.Length-1].Slider = slider;

  if (dataProvider != none)
    slider.SetObject("dataProvider", dataProvider);
  else
  {
    slider.SetFloat("minimum", min);
    slider.SetFloat("maximum", max);
    slider.SetSnapInterval(snap);
  }
  slider.SetFloat("value", FClamp(val, min, max));
  slider.AddEventListener('CLIK_change', OnSliderChanged);
}

private static function OnSliderChanged(GFxClikWidget.EventData eventData)
{
  local int i;
  local MutConfigHelper helper;
  local delegate<SliderEventListener> listener;
  local string sliderName;

  helper = GetHelper();
  for (i=0; i<helper.sliders.Length; i++)
  {
    sliderName = eventData.Target.GetString("_name");
    if (helper.sliders[i].sliderName == sliderName)
    {
      listener = helper.sliders[i].listener; // syntactially required BS
      listener(helper.sliders[i].label, eventData.target.GetFloat("value"), eventData);
      return;
    }
  }
}


public static function GfxClikWidget AddCheckBox(GFxCRZFrontEnd_ModularView ConfigView, string label, string descr, bool val, delegate<CheckBoxEventListener> listener)
{
  local GfxClikWidget checkBox;
  local MutConfigHelper helper;
 
  checkBox = GfxClikWidget(ConfigView.AddItem(ConfigView.ListObject1, "CheckBox", label, descr));
  checkBox.SetBool("selected", val);	
  checkBox.AddEventListener('CLIK_click', OnCheckboxClicked);

  helper = GetHelper();
  helper.AddCheckBoxToList(checkBox.GetString("_name"), label, listener);
  return checkBox;
}

private function AddCheckBoxToList(string checkboxName, string label, delegate<CheckBoxEventListener> listener)
{
  checkboxes.Add(1);
  checkboxes[checkboxes.Length-1].Name = checkboxName;
  checkboxes[checkboxes.Length-1].Label = label;
  checkboxes[checkboxes.Length-1].Listener = listener;
}

private static function OnCheckboxClicked(GFxClikWidget.EventData eventData)
{
  local int i;
  local MutConfigHelper helper;
  local delegate<CheckBoxEventListener> listener;

  helper = GetHelper();
  for (i=0; i<helper.checkboxes.Length; i++)
  {
    if (helper.checkboxes[i].name == eventData.Target.GetString("_name"))
    {
      listener = helper.checkboxes[i].listener; // syntactially required BS
      listener(helper.checkboxes[i].label, eventData.target.GetBool("selected"), eventData);
      return;
    }
  }
}

// string and object dictionary functions to help mutator config screens escape the "static" trap

public function string GetString(string key, optional string defaultValue)
{
  local int i;
  for (i=0; i<stringDict.length; i++)
  {
    if (stringDict[i].key == key)
      return stringDict[i].val;
  }
  return defaultValue;
}

public function SetString(string key, string value)
{
  local int i;
  for (i=0; i<stringDict.length; i++)
  {
    if (stringDict[i].key == key)
    {
      stringDict[i].val = value;
      return;
    }
  }
  stringDict.length = stringDict.length+1;
  stringDict[i].key = key;
  stringDict[i].val = value;
}

public function object GetObject(string key, optional object defaultValue)
{
  local int i;
  for (i=0; i<objectDict.length; i++)
  {
    if (objectDict[i].key == key)
      return objectDict[i].val;
  }
  return defaultValue;
}

public function SetObject(string key, object value)
{
  local int i;
  for (i=0; i<objectDict.length; i++)
  {
    if (objectDict[i].key == key)
    {
      objectDict[i].val = value;
      return;
    }
  }
  objectDict.length = objectDict.Length+1;
  objectDict[i].key = key;
  objectDict[i].val = value;
}

public function SetTimerFunc(float interval, delegate<TimerFunc> func, optional bool repeat)
{
  if (timerHandler != none)
    ClearTimer('RelayTimer');
  SetTimer(interval, repeat, 'RelayTimer');
  timerHandler = func;
}

public function ClearTimerFunc(float interval, delegate<TimerFunc> func, optional bool repeat)
{
  ClearTimer('RelayTimer');
  timerHandler = none;
}

function RelayTimer()
{
  if (timerHandler != none)
    timerHandler();
}