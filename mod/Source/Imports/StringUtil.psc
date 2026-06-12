ScriptName StringUtil Hidden
{Minimal compile-time declaration of SKSE's StringUtil native script.
The runtime implementation ships with SKSE64 (Data\Scripts\StringUtil.pex);
only the functions the mod uses are declared here.}

Int Function Find(String s, String toFind, Int startIndex = 0) Global Native
Int Function GetLength(String s) Global Native
String Function Substring(String s, Int startIndex, Int len = 0) Global Native
