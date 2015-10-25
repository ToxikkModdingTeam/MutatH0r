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
var config float Radius1, Radius2;
var float SplashRadius1, SplashRadius2;
var bool Enabled;

replication
{
  if (Role == ENetRole.ROLE_Authority && (bNetDirty || bNetInitial))
    DrawCylinder, SplashRadius1, SplashRadius2;
}

function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);

  Enabled = true;
	DrawCylinder = true;
  SplashRadius1 = Radius1;
  SplashRadius2 = Radius2;
}

simulated function PreBeginPlay()
{
  base.PreBeginPlay();
  SetTickGroup(ETickingGroup.TG_PostUpdateWork);
  Enable('Tick');
}

simulated function Tick(float DeltaTime)
{
	local UTPawn P;
  local Vector pos;
  local float height;

  if (!Enabled)
    return;

	foreach WorldInfo.AllPawns(class'UTPawn', P)
	{
		if (DetachBots && P.Controller != None && PlayerController(P.Controller) == None)
			P.DetachFromController(true);

    pos = P.CylinderComponent.GetPosition();
    height = P.CylinderComponent.CollisionHeight;

    if (SplashRadius1 != 0)
    {
			P.DrawDebugCylinder(
				pos + vect(0,0,-1) * height, 
				pos + vect(0,0,-1) * height, 
				P.CylinderComponent.CollisionRadius + SplashRadius1,
				16, 255, 0, 0, false);
    }

    if (SplashRadius2 != 0)
    {
			P.DrawDebugCylinder(
				pos + vect(0,0,-1) * height, 
				pos + vect(0,0,-1) * height, 
				P.CylinderComponent.CollisionRadius + SplashRadius2,
				16, 0, 255, 255, false);
    }

		if (DrawCylinder && PlayerController(P.Controller) == none)
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
	if (MutateString == "hb_info")
		DumpInformation(Sender);
  else if (MutateString == "hb_off")
    Enabled = false;
  else if (MutateString == "hb_on")
    Enabled = true;
	else if (left(MutateString, 7) == "hb_cyl ")
		DrawCylinder = mid(MutateString, 7) != "0";
  else if (left(MutateString, 8) == "hb_rad1 ")
    SplashRadius1 = float(mid(MutateString, 8));
  else if (left(MutateString, 8) == "hb_rad1 ")
    SplashRadius2 = float(mid(MutateString, 8));
	else if (MutateString == "hb_crouch")
		ToggleCrouchForAllBots();
	else if (MutateString == "hb_detach")
		DetachBots = !DetachBots;
	else if (MutateString == "hb_move")
		DummyMove();
	else if (Left(MutateString, 7) == "hb_pos ")
		ChangePos(float(Mid(MutateString, 7)));
	else if (Left(MutateString, 7) == "hb_height ")
		ChangeHeight(float(Mid(MutateString, 7)));
	else if (Left(MutateString, 7) == "hb_off ")
		ChangeOffset(float(Mid(MutateString, 7)));
	else
		Super.Mutate(MutateString, Sender);
}

function DumpInformation(PlayerController sender)
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
	GroupNames[0]="HITBOX";
}