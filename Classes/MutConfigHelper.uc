/*
 * This class solves 2 problems in TOXIKK 0.96's custom mutator config
 * - the mutator class / package gets garbage collected and the next call to the widget event listener causes an application crash
 * - when initializing a slider widget with a value, the widget returns 0 during the change notification instead of the current value
 */

class MutConfigHelper extends Actor;

var private class clazz;
var private array<name> ignoredEvents;

public static function NotifyPopulated(class classRef)
{  
  GetOrCreate(classRef).ignoredEvents.Length = 0;
}

public static function bool IgnoreChange(class classRef, optional name widget = '')
{
  local MutConfigHelper helper;
  local int i;

  helper = GetOrCreate(classRef);
  for (i=0; i<helper.ignoredEvents.Length; i++)
  {
    if (helper.ignoredEvents[i] == widget)
      return false;
  }

  helper.ignoredEvents.AddItem(widget);
  return true;
}

private static function MutConfigHelper GetOrCreate(class classRef)
{
  local WorldInfo world;
  local MutConfigHelper helper;
  
  world = class'WorldInfo'.static.GetWorldInfo();
  foreach world.AllActors(class'MutConfigHelper', helper)
  {
    if (helper.clazz == classRef)
      return helper;
  }

  helper = world.Spawn(class'MutConfigHelper');
  helper.clazz = classRef;
  return helper;
}
