Scriptname Weapon extends Form Hidden

; Fire this weapon base object from the specified source
Function Fire(ObjectReference akSource, Ammo akAmmo = None) native

; --- SKSE additions used by Buildnator (runtime ships with SKSE64) ---
Enchantment Function GetEnchantment() native

