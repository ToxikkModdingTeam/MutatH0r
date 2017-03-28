class DmgPlumeConfigScreen extends Actor;

var GFxCRZFrontEnd_ModularView View;
var CRZSliderWidget slDamageNumbers, slFont, slScale, slTime, slHSpeed, slHSpread, slVSpeed, slVSpread;
var CRZSliderWidget slKillSound, slKillSoundVolume;
var GfxClikWidget cbColors;
var int customPresetIndex;

function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  local GFxObject TempObj;
  local GFxObject DataProviderPlumes, DataProviderFonts, DataProviderKillSounds;
  local int i,j;
  local string presetName;
  local int presetIndex, plumeFontIndex, killSoundIndex;
  local array<string> presetNames;

  View = ConfigView;
  GetPerObjectConfigSections(class'DmgPlumeConfig', presetNames); // they come in reverse order
  presetNames.InsertItem(0, "custom");
  presetNames.AddItem("off");
  customPresetIndex = presetNames.Length - 1;

  DataProviderPlumes = ConfigView.outer.CreateArray();
  j=0;
  for(i=presetNames.Length-1; i>=0; i--)
  {
    presetName = repl(locs(presetNames[i]), " dmgplumeconfig", "");

    TempObj = ConfigView.MenuManager.CreateObject("Object");
    TempObj.SetString("label", presetName);
    DataProviderPlumes.SetElementObject(j, TempObj);

    if (presetName == class'DmgPlumeActor'.default.DmgPlumeConfig)
      presetIndex = j;
    ++j;
  }

  // fonts
  DataProviderFonts = ConfigView.outer.CreateArray();
  for(i=0; i<class'DmgPlumeActor'.default.PlumeFonts.Length; i++)
  {
    TempObj = ConfigView.MenuManager.CreateObject("Object");
    TempObj.SetString("label", class'DmgPlumeActor'.default.PlumeFonts[i].Label);
    DataProviderFonts.SetElementObject(i, TempObj);

    if (class'DmgPlumeActor'.default.PlumeFonts[i].Label == class'CRZHitIndicatorManager'.default.Font)
      plumeFontIndex = i;
  }
  
  // kill sounds
  DataProviderKillSounds = ConfigView.outer.CreateArray();
  for(i=0; i<class'DmgPlumeActor'.default.KillSounds.Length; i++)
  {
    TempObj = ConfigView.MenuManager.CreateObject("Object");
    TempObj.SetString("label", class'DmgPlumeActor'.default.KillSounds[i].Label);
    DataProviderKillSounds.SetElementObject(i, TempObj);

    if (class'DmgPlumeActor'.default.KillSounds[i].Label == class'DmgPlumeActor'.default.KillSound)
      killSoundIndex = i;
  }

  ConfigView.SetMaskBounds(ConfigView.ListObject1, 400, 975, true);
  slKillSound = AddSlider(ConfigView, "Kill Sound", "Sound played when you kill a player", 0, class'DmgPlumeActor'.default.KillSounds.Length - 1, 1, killSoundIndex, DataProviderKillSounds);
  slKillSoundVolume = AddSlider(ConfigView, "  Volume", "Kill sound volume", 0, 400, 5, int(class'DmgPlumeActor'.default.KillSoundVolume * 100));

  slDamageNumbers = AddSlider(ConfigView, "Damage Numbers", "Size and appearance of damage numbers", 0, presetNames.Length - 1, 1, presetIndex, DataProviderPlumes);

  cbColors = GfxClikWidget(ConfigView.AddItem(ConfigView.ListObject1, "CheckBox", "  Color", "Draw Damage Numbers in color"));
  cbColors.SetBool("selected", class'CRZHitIndicatorManager'.default.DamageColors.Length > 1);	
  cbColors.AddEventListener('CLIK_click', OnCheckboxClicked);

  slFont = AddSlider(ConfigView, "  Font", "Font for damage numbers", 0, -1, 1, plumeFontIndex, DataProviderFonts);
  slScale = AddSlider(ConfigView, "  Scale", "Size for damage numbers", 2, 48, 1, int(class'CRZHitIndicatorManager'.default.Scale * 16));
  slTime = AddSlider(ConfigView, "  Time", "Time for damage numbers", 1, 12, 1, int(class'CRZHitIndicatorManager'.default.Lifetime*4));
  slHSpeed = AddSlider(ConfigView, "  Horiz. Speed", "Horizontal speed of damage numbers", 0, 400, 10, class'CRZHitIndicatorManager'.default.SpeedX.Fixed);
  slHSpread = AddSlider(ConfigView, "  Horiz. Spread", "Horizontal spread damage numbers", 0, 400, 10, class'CRZHitIndicatorManager'.default.SpeedX.Random);
  slVSpeed = AddSlider(ConfigView, "  Vert. Speed", "Vertical speed of damage numbers", 0, 400, 10, class'CRZHitIndicatorManager'.default.SpeedY.Fixed);
  slVSpread = AddSlider(ConfigView, "  Vert. Spread", "Vertical spread of damage numbers", 0, 400, 10, class'CRZHitIndicatorManager'.default.SpeedY.Random);
  
  ClearTimer('Timer');
  SetTimer(0.25, true, 'Timer');
  //CRZGameViewportClient( Class'Engine'.static.GetEngine().GameViewport).PostScaleformRender = PostScaleformRender;
}

public static function CRZSliderWidget AddSlider(GFxCRZFrontEnd_ModularView ConfigView, string label, string descr, float min, float max, float snap, float val, optional GfxObject dataProvider)
{
  local CRZSliderWidget slider;

  slider = ConfigView.AddSlider(ConfigView.ListObject1, "CRZSlider", label, descr);

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

  return slider;
}

function OnSliderChanged(GFxClikWidget.EventData ev)
{
  local GFxObject DataProvider, ElementObj;
  local string dataProviderText;
  local SoundCue cue;
  local float value;
  local int i;

  value = ev.target.GetFloat("value");

  DataProvider = ev.target.GetObject("dataProvider");
  dataProviderText = "";
  if (DataProvider != none)
  {
    ElementObj = DataProvider.GetElementObject(int(value));
    if (ElementObj != none)
      dataProviderText = ElementObj.GetString("label");
  }


  if (ev.Target.GetString("_name") == slKillSound.GetString("_name"))
  {
    class'DmgPlumeActor'.default.KillSound = dataProviderText;
    cue = class'DmgPlumeActor'.static.GetKillSound(dataProviderText);
    if (cue != none)
      WorldInfo.GetALocalPlayerController().ClientPlaySound(cue);
  }
  else if (ev.Target.GetString("_name") == slKillSoundVolume.GetString("_name"))
    class'DmgPlumeActor'.default.KillSoundVolume = value/100;
  else if (ev.Target.GetString("_name") == slDamageNumbers.GetString("_name"))
  {
    class'DmgPlumeActor'.default.DmgPlumeConfig = dataProviderText;
    ActivatePlumePreset(dataProviderText);
    cbColors.SetBool("selected", class'CRZHitIndicatorManager'.default.DamageColors.Length > 1);
    for (i=0; i<class'DmgPlumeActor'.default.PlumeFonts.Length; i++)
    {
      if (class'DmgPlumeActor'.default.PlumeFonts[i].Uri == class'CRZHitIndicatorManager'.default.Font)
      {
        slFont.SetInt("value", i);
        break;
      }
    }
    slScale.SetInt("value", int(class'CRZHitIndicatorManager'.default.Scale * 16));
    slTime.SetInt("value", int(class'CRZHitIndicatorManager'.default.Lifetime * 4));
    slHSpeed.SetInt("value", class'CRZHitIndicatorManager'.default.SpeedX.Fixed);
    slHSpread.SetInt("value", class'CRZHitIndicatorManager'.default.SpeedX.Random);
    slVSpeed.SetInt("value", class'CRZHitIndicatorManager'.default.SpeedY.Fixed);
    slVSpread.SetInt("value", class'CRZHitIndicatorManager'.default.SpeedY.Random);
    CRZHud(WorldInfo.GetALocalPlayerController().myHUD).PlumeFont = none;
  }
  else
  {
    if (ev.Target.GetString("_name") == slFont.GetString("_name"))
    {
      class'CRZHitIndicatorManager'.default.Font = class'DmgPlumeActor'.default.PlumeFonts[value].Uri;
      CRZHud(WorldInfo.GetALocalPlayerController().myHUD).PlumeFont = none;
    }
    else if (ev.Target.GetString("_name") == slScale.GetString("_name"))
      class'CRZHitIndicatorManager'.default.Scale = value / 16;
    else if (ev.Target.GetString("_name") == slTime.GetString("_name"))
      class'CRZHitIndicatorManager'.default.Lifetime = value / 4;
    else if (ev.Target.GetString("_name") == slHSpeed.GetString("_name"))
      class'CRZHitIndicatorManager'.default.SpeedX.Fixed = value;
    else if (ev.Target.GetString("_name") == slHSpread.GetString("_name"))
      class'CRZHitIndicatorManager'.default.SpeedX.Random = value;
    else if (ev.Target.GetString("_name") == slVSpeed.GetString("_name"))
      class'CRZHitIndicatorManager'.default.SpeedY.Fixed = value;
    else if (ev.Target.GetString("_name") == slVSpread.GetString("_name"))
      class'CRZHitIndicatorManager'.default.SpeedY.Random = value;

    slDamageNumbers.SetInt("value", customPresetIndex);
    class'CRZHitIndicatorManager'.static.StaticSaveConfig();
  }

  class'DmgPlumeActor'.static.StaticSaveConfig();
}

private function OnCheckboxClicked(GFxClikWidget.EventData eventData)
{
  class'CRZHitIndicatorManager'.default.DamageColors.Length = 0;
  if (cbColors.GetBool("selected"))
  {
    AddPlumeColor(0, 255,255,255);
    AddPlumeColor(20, 255,255,160);
    AddPlumeColor(35, 255,255,64);
    AddPlumeColor(45, 100,255,100);
    AddPlumeColor(70, 255,65,255);
    AddPlumeColor(100, 255,48,48);
  }
  else
  {
    AddPlumeColor(0, 255, 255, 255);
  }

  slDamageNumbers.SetInt("value", customPresetIndex);
  class'CRZHitIndicatorManager'.static.StaticSaveConfig();
}

function AddPlumeColor(int damage, int r, int g, int b)
{
  local int i;
  
  i = class'CRZHitIndicatorManager'.default.DamageColors.Length;
  class'CRZHitIndicatorManager'.default.DamageColors.Length = i + 1;
  class'CRZHitIndicatorManager'.default.DamageColors[i].Damage = damage;
  class'CRZHitIndicatorManager'.default.DamageColors[i].Color = MakeColor(r, g, b, 255);
}

function ActivatePlumePreset(string presetName)
{
  local DmgPlumeConfig preset;

  class'DmgPlumeActor'.default.DmgPlumeConfig = presetName;
  class'DmgPlumeActor'.static.StaticSaveConfig();

  class'CRZHitIndicatorManager'.default.bShowDamagePlumes = !(presetName ~= "off");
  if (!(presetName ~= "off" || presetName ~= "custom"))
  {
    preset = new (none, presetName) class'DmgPlumeConfig';
    class'CRZHitIndicatorManager'.default.Font = preset.Font;
    class'CRZHitIndicatorManager'.default.Scale = preset.Scale;
    class'CRZHitIndicatorManager'.default.SpeedX = preset.SpeedX;
    class'CRZHitIndicatorManager'.default.SpeedY = preset.SpeedY;
    class'CRZHitIndicatorManager'.default.Lifetime = preset.Lifetime;
    class'CRZHitIndicatorManager'.default.DamageColors = preset.DamageColors;
  }
  class'CRZHitIndicatorManager'.static.StaticSaveConfig();
}


function Timer()
{
  //CRZHud(WorldInfo.GetALocalPlayerController().myHUD).AddPlume(rand(6)*20, vect(1000,0,150));
  if (View.MenuManager == none || view.MenuManager.ViewStack.Length == 0 || view.MenuManager.ViewStack[view.MenuManager.ViewStack.Length - 1] != View)
  {
    //`log("cleaning up DmgPlumeConfigScreen");
    ClearTimer('Timer');
    View = none;
    self.Destroy();
  }
}

function PostScaleformRender(Canvas canvas)
{
  local vector pos, dir;
  local CRZHud hud;
  local PlayerController pc;

  pos=vect(100, 0, 150);
  dir=vect(1,0,0);

  pc = WorldInfo.GetALocalPlayerController();
  pc.SetLocation(pos);
  pc.SetRotation(Rotator(dir));
  pc.PlayerCamera.SetFOV(110);
  pc.PlayerCamera.SetLocation(pos);
  pc.PlayerCamera.SetRotation(Rotator(dir));

  hud=CRZHud(pc.myHUD);
  hud.Canvas = canvas;
  hud.ResolutionScaleX = Canvas.ClipX/2560;
	hud.ResolutionScale = Canvas.ClipY/1440;

  hud.DrawDamagePlumes(pos, dir);
}

DefaultProperties
{
}
