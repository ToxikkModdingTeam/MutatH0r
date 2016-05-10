class Utils extends Object;

static function string GetOption(string options, string optionName)
{
  local int i, j;
  
  optionName = "?" $ optionName $ "=";
  i=instr(options, optionName, false, true);
  if (i<0)
    return "";
  i=i+len(optionName);
  j=instr(options, "?", false, false, i);
  if (j < 0) 
    j=len(options);
  return mid(options, i, j-i);
}

