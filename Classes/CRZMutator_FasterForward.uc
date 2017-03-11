class CRZMutator_FasterForward extends CRZMutator config(MutatH0r);

var config float GameSpeed;

function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);

  if (GameSpeed == 0)
    GameSpeed = 1.0;
	WorldInfo.Game.SetGameSpeed(GameSpeed);
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  super.PopulateConfigView(ConfigView, MutatorDataProvider);

  if (default.GameSpeed == 0)
    default.GameSpeed = 1.0;

  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_FasterForward');
  class'MutConfigHelper'.static.AddSlider(ConfigView, "Game Speed %", "Change the gamespeed [100%]", 50, 350, 1, default.GameSpeed * 100, OnSliderChanged);
}

function static OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  default.GameSpeed = value / 100;
  StaticSaveConfig();
}


defaultproperties
{
//	GroupNames[0]="GAMESPEED"
}
