/*
 * This class solves a few problems in TOXIKK 0.96's custom mutator config
 * - the mutator class / package gets garbage collected and the next call to the widget event listener causes an application crash
 * - when initializing a slider widget with a value, the widget returns 0 during the change notification instead of the current value
 * - this class wraps the event listeners and provides additional context information so that multiple controls can use the same handler
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
  var bool firstEventSkipped;
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
  local CRZSliderWidget Slider; 
  local MutConfigHelper helper;

  Slider = ConfigView.AddSlider(ConfigView.ListObject1, "CRZSlider", label, descr);
  if (dataProvider != None)
    slider.SetObject("dataProvider", dataProvider);
  Slider.SetFloat("minimum", min);
  Slider.SetFloat("maximum", max);
  Slider.SetSnapInterval(snap);
  Slider.SetFloat("value", FClamp(val, min, max));	
  Slider.AddEventListener('CLIK_change', OnSliderChanged);
  
  helper = GetHelper();
  helper.AddSliderToList(slider.GetString("_name"), label, listener);
  return Slider;
}

private function AddSliderToList(string sliderName, string label, delegate<SliderEventListener> listener)
{
  Sliders.Add(1);
  Sliders[Sliders.Length-1].SliderName = sliderName;
  Sliders[Sliders.Length-1].Label = label;
  Sliders[Sliders.Length-1].Listener = listener;
  sliders[sliders.length-1].firstEventSkipped = false;
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
      if (helper.sliders[i].firstEventSkipped)
      {
        listener = helper.sliders[i].listener; // syntactially required BS
        listener(helper.sliders[i].label, eventData.target.GetFloat("value"), eventData);
      }
      else
        helper.sliders[i].firstEventSkipped = true;
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

private function AddCheckBoxToList(string checkboxName, string label, delegate<SliderEventListener> listener)
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
