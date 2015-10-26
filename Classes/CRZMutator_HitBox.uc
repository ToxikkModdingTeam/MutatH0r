// MutatH0r.CRZMutator_HitBox
// ----------------
// draws the collision cylinder and 2 splash area circles around all bots
// and allows detaching their controller so that they don't move
// ----------------
// by PredatH0r
//================================================================

class CRZMutator_HitBox extends UTMutator config(MutatH0r);

var bool DrawCylinder;
var bool Crouch;
var bool DetachBots;
var bool receivedWelcomeMessage;

replication
{
  if (Role == ENetRole.ROLE_Authority && (bNetDirty || bNetInitial))
    DrawCylinder;
}

function InitMutator(string Options, out string ErrorMessage)
{
  super.InitMutator(Options, ErrorMessage);
  DrawCylinder = true;
}

simulated function PostBeginPlay()
{
  super.PostBeginPlay();
  SetTickGroup(ETickingGroup.TG_PostUpdateWork);
  Enable('Tick');

  // in NM_Standalone, messages aren't printed at this time, so set a timer
  if (WorldInfo.NetMode == NM_Client || WorldInfo.NetMode == NM_Standalone) 
    SetTimer(1.0, true, 'ShowWelcomeMessage');
}

simulated function ShowWelcomeMessage()
{
  local PlayerController pc;

  if (receivedWelcomeMessage)
    return;

  foreach WorldInfo.LocalPlayerControllers(class'PlayerController', pc)
  {
    pc.ClientMessage("Use console command <font color='#ffff00'>mutate hb help</font> to modify the <font color='#ffff00'>HitBox</font>.");
    receivedWelcomeMessage = true;
  }

  if (receivedWelcomeMessage)
    ClearTimer('ShowWelcomeMessage');
}

simulated function Tick(float DeltaTime)
{
  local UTPawn P;
  local Vector pos;
  local float height;

  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    if (DetachBots && P.Controller != None && P.Controller.IsA('AIController'))
      P.DetachFromController(true);
    DetachBots = false;

    pos = P.Location;
    height = P.CylinderComponent.CollisionHeight;
    if (DrawCylinder && PlayerController(P.Controller) != GetALocalPlayerController())
    {
      P.DrawDebugCylinder(
        pos + vect(0,0,1) * height, 
        pos + vect(0,0,-1) * height, 
        P.CylinderComponent.CollisionRadius,
        16, 255, 255, 0, false);
    }
  }
}

function Mutate(string MutateString, PlayerController Sender)
{
  local PlayerController pc;
  local string cmd;
  local string arg;
  local int i;

  if (left(MutateString, 3) != "hb ")
  {
    super.Mutate(MutateString, Sender);
    return;
  }

  cmd = mid(MutateString, 3);
  i = instr(cmd, " ");
  if (i >= 0)
  {
    arg = mid(cmd, i+1);
    cmd = left(cmd, i);
  }

  if (cmd == "help")
  {
    ShowHelp(Sender);
    return;
  }
  if (cmd == "info")
  {
    ShowInfo(Sender);
    return;
  }

  if (cmd ~= "DrawCylinder")
    DrawCylinder = bool(arg);
  else if (WorldInfo.NetMode == NM_Standalone)
  {
    if (cmd ~= "crouch")
      ToggleCrouchForAllBots();
    else if (cmd ~= "detach")
      DetachBots = true;
    else if (cmd ~= "move")
      DummyMove();
    else if (cmd ~= "pos")
      ChangePos(float(arg));
    else if (cmd ~= "height")
      ChangeHeight(float(arg));
    else if (cmd ~= "offset")
      ChangeOffset(float(arg));
    else
      goto unsupported;
  }
  else
  {
unsupported:
    sender.ClientMessage("HitBox: unsupported command: " $ cmd @ arg);
    return;
  }

  `log("HitBox mutated:" @ cmd @ arg);

  if (sender == none)
    return;

  // tell everyone that a setting was changed
  foreach WorldInfo.AllControllers(class'PlayerController', pc)
  {
    pc.ClientMessage("Use <font color='#00ffff'>mutate hb info</font> to show the current settings.");
    pc.ClientMessage(sender.PlayerReplicationInfo.PlayerName $ " <font color='#ff0000'>modified HitBox setting</font>: " $ cmd @ arg);
  }
}

function ShowHelp(PlayerController pc)
{
  //pc.ClientMessage("mutate hb [setting] [value]: change [setting] to [value] (see 'mutate ro info')", 'Info');
  pc.ClientMessage("mutate hb info: show current hit cylinder settings", 'Info');
  pc.ClientMessage("mutate hb DrawCylinder [0/1]: disable/enable drawing of the yellow hit cylinder", 'Info');
  pc.ClientMessage("_____ HitBox help _____");
}

function ShowInfo(PlayerController pc)
{
  local UTPawn P;

  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    if (PlayerController(P.Controller) != None)
      continue;
    `log("Pawn: " $ P.Name);
    `log("  Location=" $ P.Location $ "; BaseTranslationOffset=" $ P.BaseTranslationOffset $ "; MeshTranslationOffset=" $ P.MeshTranslationOffset);
    `log("  CrouchTranslationOffset=" $ P.CrouchTranslationOffset $ "; CrouchHeight=" $ P.CrouchHeight $ "; CrouchMeshZOffset=" $ P.CrouchMeshZOffset);
    `log("  Cylinder: Position=" $ P.CylinderComponent.GetPosition() $ "; CollHeight=" $ P.CylinderComponent.CollisionHeight);
    break;
  }
}

function ToggleCrouchForAllBots()
{
  local UTPawn P;

  Crouch = !Crouch;
  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    if (PlayerController(P.Controller) != None)
      continue;
    if (Crouch && !P.bIsCrouched)
      P.ShouldCrouch(true);
    else if (!Crouch && P.bIsCrouched)
      P.UnCrouch();
  }		
}

function ChangePos(float delta)
{
  local UTPawn P;

  Crouch = !Crouch;
  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    if (PlayerController(P.Controller) == None)
      P.Move(vect(0,0,1) * delta);
  }		
}

function ChangeHeight(float delta)
{
  local UTPawn P;

  Crouch = !Crouch;
  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    if (PlayerController(P.Controller) != None)
      continue;
    P.CylinderComponent.SetCylinderSize(P.CylinderComponent.CollisionRadius, P.CylinderComponent.CollisionHeight + delta);
    P.Move(vect(0,0,1));
    P.Move(vect(0,0,-1));
  }		
}

function ChangeOffset(float delta)
{
  local UTPawn P;

  Crouch = !Crouch;
  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    if (PlayerController(P.Controller) != None)
      continue;
    P.BaseTranslationOffset += delta;
    P.Move(vect(0,0,1));
    P.Move(vect(0,0,-1));
  }		
}

function DummyMove()
{
  local UTPawn P;

  foreach WorldInfo.AllPawns(class'UTPawn', P)
  {
    if (PlayerController(P.Controller) != None)
      continue;
    P.Move(vect(0,0,1));
    P.Move(vect(0,0,-1));
  }
}

defaultproperties
{
  RemoteRole=ROLE_SimulatedProxy
  bAlwaysRelevant=true
}