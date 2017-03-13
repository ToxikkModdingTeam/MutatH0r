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
  var CRZSliderWidget widget;
  var GfxObject dataProvider;
  var string sliderName;
  var delegate<SliderEventListener> listener;
  var string label;
  var float min,max,snap,value;
  var bool initialized;
};

struct CheckboxMapping
{
  var string name;
  var delegate<CheckBoxEventListener> listener;
  var string label;
};

var private class clazz;
var private array<SliderMapping> sliders;
var private array<CheckboxMapping> checkboxes;

static delegate SliderEventListener(string label, float value, GFxClikWidget.EventData data);
static delegate CheckBoxEventListener(string label, bool value, GFxClikWidget.EventData data);

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
}

private static function MutConfigHelper GetHelper()
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

private function AddSliderToList(CRZSliderWidget slider, string label, float min, float max, float snap, float val, delegate<SliderEventListener> listener, GfxObject dataProvider)
{
  Sliders.Add(1);
  Sliders[Sliders.Length-1].Widget = slider;
  Sliders[Sliders.Length-1].SliderName = slider.GetString("_name");
  Sliders[Sliders.Length-1].DataProvider = dataProvider;
  Sliders[Sliders.Length-1].Label = label;
  Sliders[Sliders.Length-1].Listener = listener;
  sliders[sliders.length-1].min = min;
  sliders[sliders.length-1].max = max;
  sliders[sliders.length-1].snap = snap;
  sliders[sliders.length-1].value = val;
  sliders[sliders.length-1].initialized = false;

  // delay init of the slider for 1 Tick to fix issues with incorrect change notifications and wrong dataProvider value
  GotoState('InitPending');
}

function Tick(float deltaTime)
{
}

state InitPending 
{
  function Tick(float deltaTime)
  {
    local int i;
    local SliderMapping slider;

    for (i=0; i<Sliders.Length; i++)
    {
      slider = Sliders[i];
      if (slider.initialized)
        continue;
      if (slider.dataProvider != none)
        slider.widget.SetObject("dataProvider", slider.dataProvider);
      else
      {
        slider.widget.SetFloat("minimum", slider.min);
        slider.widget.SetFloat("maximum", slider.max);
        slider.widget.SetSnapInterval(slider.snap);
      }
      slider.widget.SetFloat("value", FClamp(slider.value, slider.min, slider.max));
      slider.widget.AddEventListener('CLIK_change', OnSliderChanged);
      slider.initialized = true;
    }
    GotoState('');
    Disable('Tick');
  }
Begin:
  Enable('Tick');
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
