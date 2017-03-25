class CRZMutator_DmgPlume extends CRZMutator config (MutatH0r);


struct PlumeReceiver
{
  var CRZPlayerController Controller;
  var DmgPlumeActor Actor;
};


// server
var array<PlumeReceiver> PlumeReceivers;

// labels for the config controls, also used to identify value changes
const LBL_DamageNumbers = "Damage Numbers";
const LBL_Font = "  Font";
const LBL_Scale = "  Scale (1/16)";
const LBL_Time = "  Time (1/4sec)";
const LBL_HSpeed = "  Horiz. Speed";
const LBL_HSpread = "  Horiz. Spread";
const LBL_VSpeed = "  Vert. Speed";
const LBL_VSpread = "  Vert. Spread";
const LBL_KillSound = "Kill Sound";
const LBL_KillSoundVolume = "Kill Sound Vol.";

function bool HasPovOfAttacker(CRZPlayerController player, Controller attacker)
{
  return player.RealViewTarget == none ? (player == attacker) : (player.RealViewTarget == attacker.PlayerReplicationInfo);
}


function int GetOrAddPlumeReceiver(CRZPlayerController C)
{
  local int i;

  if (C == none)
    return -1;

  // find or create plume receiver
  for (i=0; i<PlumeReceivers.Length; i++)
  {
    if (PlumeReceivers[i].Controller == C)
      return i;
  }

  PlumeReceivers.Add(1);
  PlumeReceivers[i].Controller = C;
  PlumeReceivers[i].Actor = Spawn(class'DmgPlumeActor', C);
  PlumeReceivers[i].Actor.Mut = self;
  return i;
}

function NotifyLogin(Controller C)
{
  local CRZPlayerController pc;

  super.NotifyLogin(C);

  // DmgPlumeActor must be instantiated on the client to know if he is typing status
  pc = CRZPlayerController(C);
  if (pc != None)
    GetOrAddPlumeReceiver(pc);
}

function NotifyLogout(Controller C)
{
  local int i, j, playerId;

  if (CRZPlayerController(C) != None)
  {
    for (i=0; i<PlumeReceivers.Length; i++)
    {
      if (PlumeReceivers[i].Controller == C)
      { 
        // tell all clients that the player isn't typing anymore (he may reconnect later, and should not have a chat bubble)
        if (PlumeReceivers[i].Actor.isTyping)
        {
          playerId = C.PlayerReplicationInfo.PlayerID;
          for (j=0; j<PlumeReceivers.Length; j++)
          {
            if (PlumeReceivers[j].Controller != C)
              PlumeReceivers[j].Actor.ClientNotifyIsTyping(playerId, false);
          }
        }

        PlumeReceivers[i].Actor.Destroy();
        PlumeReceivers.Remove(i, 1);
        break;
      }
    }
  }

  super.NotifyLogout(C);
}

function ScoreKill (Controller killer, Controller killed)
{
  local int i;
  local CRZPlayerController pc;

  super.ScoreKill(killer, killed);

  if (killer == none || killer == killed)
    return;

  foreach WorldInfo.AllControllers(class'CRZPlayerController', PC)
  {
    if (!HasPovOfAttacker(pc, killer))
      continue;
    i = GetOrAddPlumeReceiver(pc);
    PlumeReceivers[i].Actor.PlayKillSound();
  }
}

static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
{
  local GFxObject TempObj;
  local GFxObject DataProviderPlumes, DataProviderFonts, DataProviderKillSounds;
  local int i,j;
  local array<string> presetNames;
  local string presetName;
  local int presetIndex, plumeFontIndex, killSoundIndex;
  local MutConfigHelper helper;
  local PlayerController pc;

  super.PopulateConfigView(ConfigView, MutatorDataProvider);
  
  if (!GetPerObjectConfigSections(class'DmgPlumeConfig', presetNames)) // names are returned in reverse order
  {
    //presetNames.AddItem("colored");
  }
  presetNames.AddItem("custom");
  presetNames.AddItem("off");

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

    if (class'DmgPlumeActor'.default.PlumeFonts[i].Label == class'CRZHitIndicatorConfig'.default.Font)
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
  class'MutConfigHelper'.static.NotifyPopulated(class'CRZMutator_DmgPlume');
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_DamageNumbers, "Size and appearance of damage numbers", 0, presetNames.Length - 1, 1, presetIndex, static.OnSliderChanged, DataProviderPlumes);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_Font, "Font for damage numbers", 0, -1, 1, plumeFontIndex, static.OnSliderChanged, DataProviderFonts);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_Scale, "Size for damage numbers", 2, 48, 1, int(class'CRZHitIndicatorConfig'.default.DrawScale * 16), static.OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_Time, "Time for damage numbers", 1, 12, 1, int(class'CRZHitIndicatorConfig'.default.Lifetime*4), static.OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_HSpeed, "Horizontal speed of damage numbers", 0, 400, 10, class'CRZHitIndicatorConfig'.default.SpeedX.Fixed, static.OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_HSpread, "Horizontal spread damage numbers", 0, 400, 10, class'CRZHitIndicatorConfig'.default.SpeedX.Random, static.OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_VSpeed, "Vertical speed of damage numbers", 0, 400, 10, class'CRZHitIndicatorConfig'.default.SpeedY.Fixed, static.OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_VSpread, "Vertical spread of damage numbers", 0, 400, 10, class'CRZHitIndicatorConfig'.default.SpeedY.Random, static.OnSliderChanged);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_KillSound, "Sound played when you kill a player", 0, class'DmgPlumeActor'.default.KillSounds.Length - 1, 1, killSoundIndex, static.OnSliderChanged, DataProviderKillSounds);
  class'MutConfigHelper'.static.AddSlider(ConfigView, LBL_KillSoundVolume, "Kill sound volume", 0, 400, 5, int(class'DmgPlumeActor'.default.KillSoundVolume * 100), static.OnSliderChanged);
  
  helper = class'MutConfigHelper'.static.GetHelper();

  //foreach class'WorldInfo'.static.GetWorldInfo().AllControllers(class'PlayerController', pc)
  if (true)
  {
    pc = class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController();
    `log("found a local player controller: "$ pc $ " class=" $ pc.class.Name);
    `log("hud: " $ pc.myHUD $ ", class=" $ pc.myHUD.class.Name);
    `log("hud mode: " $ CRZHud(pc.myHUD).CurrentHudMode);
    `log("hud movie: " $ CRZHud(pc.myHUD).HudMovie);
    `log("hud class: " $ CRZHud(pc.myHUD).HudClass);
    class'MutConfigHelper'.static.GetHelper().SetObject("HudMovie", CRZHud(pc.myHUD).HudMovie);
  }
  
  helper.SetTimerFunc(0.25, StaticTimer, true);
  helper.SetObject("renderer", class'DmgPlumeConfigInteraction'.static.Create(helper, pc, true));
}

static function StaticTimer()
{
  local MutConfigHelper helper;

  `log("CRZMutator_DmbPlume.StaticTimer()");
  
  helper = class'MutConfigHelper'.static.GetHelper();
  if (CRZHud(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().myHUD).HudMovie != helper.GetObject("HudMovie"))
  {
    `log("left menu");
    helper.ClearTimer();
    return;
  }

  CRZHud(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().myHUD).AddPlume(rand(6)*20, vect(0,0,0));
}

static function OnSliderChanged(string label, float value, GFxClikWidget.EventData ev)
{
  local GFxObject DataProvider, ElementObj;
  local string dataProviderText;
  local SoundCue cue;
  local MutConfigHelper helper;

  DataProvider = ev.target.GetObject("dataProvider");
  dataProviderText = "";
  if (DataProvider != none)
  {
    ElementObj = DataProvider.GetElementObject(int(value));
    if (ElementObj != none)
      dataProviderText = ElementObj.GetString("label");
  }

  if (label == LBL_DamageNumbers)
  {
    class'DmgPlumeActor'.default.DmgPlumeConfig = dataProviderText;
    ActivatePlumePreset(dataProviderText);
    helper = class'MutConfigHelper'.static.GetHelper();
    helper.SetSliderValue(LBL_Scale, int(class'CRZHitIndicatorConfig'.default.DrawScale * 16));
    helper.SetSliderValue(LBL_Time, int(class'CRZHitIndicatorConfig'.default.Lifetime * 4));
    helper.SetSliderValue(LBL_HSpeed, class'CRZHitIndicatorConfig'.default.SpeedX.Fixed);
    helper.SetSliderValue(LBL_HSpread, class'CRZHitIndicatorConfig'.default.SpeedX.Random);
    helper.SetSliderValue(LBL_VSpeed, class'CRZHitIndicatorConfig'.default.SpeedY.Fixed);
    helper.SetSliderValue(LBL_VSpread, class'CRZHitIndicatorConfig'.default.SpeedY.Random);
  }
  else if (left(label, 2) == "  ")
  {
    if (label == LBL_Font)
      class'CRZHitIndicatorConfig'.default.Font = class'DmgPlumeActor'.default.PlumeFonts[value].Uri;
    else if (label == LBL_Scale)
      class'CRZHitIndicatorConfig'.default.DrawScale = value / 16;
    else if (label == LBL_Time)
      class'CRZHitIndicatorConfig'.default.Lifetime = value / 4;
    else if (label == LBL_HSpeed)
      class'CRZHitIndicatorConfig'.default.SpeedX.Fixed = value;
    else if (label == LBL_HSpread)
      class'CRZHitIndicatorConfig'.default.SpeedX.Random = value;
    else if (label == LBL_VSpeed)
      class'CRZHitIndicatorConfig'.default.SpeedY.Fixed = value;
    else if (label == LBL_VSpread)
      class'CRZHitIndicatorConfig'.default.SpeedY.Random = value;

    helper = class'MutConfigHelper'.static.GetHelper();
    helper.SetSliderValue(LBL_DamageNumbers, 1);

    class'CRZHitIndicatorConfig'.static.StaticSaveConfig();
  }
  else if (label == LBL_KillSound)
  {
    class'DmgPlumeActor'.default.KillSound = dataProviderText;
    cue = class'DmgPlumeActor'.static.GetKillSound(dataProviderText);
    if (cue != none)
      class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientPlaySound(cue);
  }
  else if (label == LBL_KillSoundVolume)
    class'DmgPlumeActor'.default.KillSoundVolume = value/100;

  class'DmgPlumeActor'.static.StaticSaveConfig();
}

static function ActivatePlumePreset(string presetName)
{
  local DmgPlumeConfig preset;

  class'DmgPlumeActor'.default.DmgPlumeConfig = presetName;
  class'DmgPlumeActor'.static.StaticSaveConfig();

  class'CRZHitIndicatorConfig'.default.bShowDamagePlumes = !(presetName ~= "off");
  if (!(presetName ~= "off" || presetName ~= "custom"))
  {
    preset = new (none, presetName) class'DmgPlumeConfig';
    class'CRZHitIndicatorConfig'.default.Font = preset.Font;
    class'CRZHitIndicatorConfig'.default.DrawScale = preset.DrawScale;
    class'CRZHitIndicatorConfig'.default.SpeedX = preset.SpeedX;
    class'CRZHitIndicatorConfig'.default.SpeedY = preset.SpeedY;
    class'CRZHitIndicatorConfig'.default.Lifetime = preset.Lifetime;
    class'CRZHitIndicatorConfig'.default.DamageColors = preset.DamageColors;
  }
  class'CRZHitIndicatorConfig'.static.StaticSaveConfig();
}

defaultproperties
{
}