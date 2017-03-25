class DmgPlumeConfigInteraction extends Interaction;

var Actor owner;

static function DmgPlumeConfigInteraction Create(Actor theOwner, PlayerController controller, optional bool bReturnExisting=true)
{
  local DmgPlumeConfigInteraction newInt;
  local int i;
 
  if (bReturnExisting)
  {
    for (i=0; i<controller.Interactions.length; i++)
    {
      if (controller.Interactions[i].class == default.class)
        return DmgPlumeConfigInteraction(controller.Interactions[i]);
    }
  }
 
  newInt = new(LocalPlayer(controller.Player).ViewportClient) default.class;
  LocalPlayer(controller.Player).ViewportClient.InsertInteraction(newInt, 0);
  controller.Interactions.InsertItem(0, newInt);
  newInt.Owner = theOwner;
  return newInt;
}

event PostRender(Canvas canvas)
{
  local vector pos, dir;
  local CRZHud hud;

  if (Owner == None) // actor destroyed when match is over
    return;

  pos=vect(0,-500,0);
  dir=vect(0,1,0);
  hud=CRZHud(owner.GetALocalPlayerController().myHUD);
  hud.Canvas = canvas;
  hud.DrawDamagePlumes(pos, dir);
}

DefaultProperties
{
}
