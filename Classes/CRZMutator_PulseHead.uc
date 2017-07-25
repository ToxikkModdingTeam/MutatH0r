// MutatH0r.CRZMutator_PulseHead
// ----------------
// scales Pawn head size in a sine wave over time
// also adjusts hit box to match the player model as close as possible
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_PulseHead extends CRZMutator config(MutatH0r);

const BaseTransOff = 13.25;         // 14.0 - 0.75
const CorrCylinderHeight = 48.25;   // 49.0 - 0.75
const CorrCrouchHeight = 34.0;      // 29.0 + 5.0
const CorrCrouchTransOff = 29.0;    // 14.0 + 20.0 - 5.0
const PulseFactor = 3.0;

var config bool bHeadShotScores2;

var repnotify float _Phase;

var JsonObject perActorInfo;

replication
{
  if ( (bNetInitial || bNetDirty) && Role == ROLE_Authority )
     _Phase;
}

event PreBeginPlay()
{
  Super.PreBeginPlay();
  SetTickGroup(ETickingGroup.TG_PreAsyncWork);
  Enable('Tick');
}

simulated event Tick(float DeltaTime)
{
  local UTPawn P;
  local float Scale;
  local float extraHeadHeight;
  local JsonObject newPerActorInfo;
  local float baseCylinderHeight;
  local float adjustedActorPosition;
  local bool prevCrouch;

  _Phase += DeltaTime;
  if (_Phase > 1)
    _Phase = _Phase - 1;

  newPerActorInfo = new class'JsonObject';
  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    // get values from previous Timer call
    adjustedActorPosition = perActorInfo.GetFloatValue(P.Name $ "_Pos");
    prevCrouch = perActorInfo.GetBoolValue(P.Name $ "_Crouch");
  
    //Scale = P.IsAliveAndWell() ? PulseFactor ** Sin(_Phase * 2 * PI) : 1.0;
    Scale = P.IsAliveAndWell() ? 0.75 + (PulseFactor-0.75) * (0.5 + Sin(2.0 * Pi * _Phase + 1.75 * PI)/2) : 1.0;
    P.SetHeadScale(Scale);

    extraHeadHeight = (Scale-1) * 5;
    
    baseCylinderHeight = P.bIsCrouched ? CorrCrouchHeight : CorrCylinderHeight;

    if (!P.bIsCrouched && prevCrouch) // engine changed pawn position in UnCrouch
      adjustedActorPosition = 0; 

    P.Move(vect(0,0,1) * (extraHeadHeight - adjustedActorPosition));
    P.CylinderComponent.SetCylinderSize(P.CylinderComponent.CollisionRadius, baseCylinderHeight + extraHeadHeight);
    P.BaseTranslationOffset = BaseTransOff - extraHeadHeight;
    P.Mesh.SetTranslation(vect(0,0,1) * P.BaseTranslationOffset);
    P.CrouchTranslationOffset = CorrCrouchTransOff - extraHeadHeight;
    P.CrouchHeight = CorrCrouchHeight + extraHeadHeight;
    P.CrouchMeshZOffset = P.bIsCrouched ? CorrCylinderHeight - CorrCrouchHeight : 0.0;
    p.BaseEyeHeight -= extraHeadHeight - adjustedActorPosition;


    // remember values for next Timer call
    newPerActorInfo.SetFloatValue(P.Name $ "_Pos", extraHeadHeight);
    newPerActorInfo.SetBoolValue(P.Name $ "_Crouch", P.bIsCrouched);
  }
  perActorInfo = newPerActorInfo;
}

simulated event ReplicatedEvent(name varName)
{
  _Phase = _Phase + TimeSinceLastTick;
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
  local UTPawn Victim;
  
  Victim = UTPawn(Killed);
  if (Victim != None && bHeadShotScores2 && InStr(caps(string(damageType)), "HEADSHOT") >= 0)
  {
    //Killer.PlayerReplicationInfo.Kills += 1; // Kills is not used at all
    Killer.PlayerReplicationInfo.Score += 1; // the "KILL" column on the scoreboard and win-condition are both using Score
  }
  
  return Super.PreventDeath(Killed, Killer, damageType, HitLocation);
}


//static function PopulateConfigView(GFxCRZFrontEnd_ModularView ConfigView, optional CRZUIDataProvider_Mutator MutatorDataProvider)
//{
//	local CRZSliderWidget Slider; 

//	super.PopulateConfigView(ConfigView, MutatorDataProvider);
  
//	Slider = ConfigView.AddSlider( ConfigView.ListObject1, "CRZSlider",MutatorDataProvider.ListOptions[0].OptionLabel, MutatorDataProvider.ListOptions[0].OptionDesc);
  
//	Slider.SetFloat("minimum", 0.75);
//	Slider.SetFloat("maximum", 3.0);
//	Slider.SetSnapInterval(0.25);
//	/*Slider.SetString("smallSnap","0.1")*/;
//	Slider.SetFloat("value", default.PulseFactor);
  
//	Slider.AddEventListener('CLIK_change', OnMaxSizeChanged);
//}

//function static OnMaxSizeChanged(GFxClikWidget.EventData ev)
//{
//	default.PulseFactor = ev.target.GetFloat("value");
//	StaticSaveConfig();
//}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
//  GroupNames[0]="HEADSIZE";
  bAllowMXPSave=true
  bAllowSCSave=false
  bRequiresDownloadOnClient=true
}