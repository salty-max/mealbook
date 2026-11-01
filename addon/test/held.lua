-- held(locale): true when the locale's language file is the names-only stub
-- written while the language is held back (HIDDEN_LOCALES in addon-kit).
-- Real files carry no mark, so restoring a language needs no edit here.
return function(locale)
  local f = io.open("addon/Mealbook/Text_" .. locale .. ".lua", "r")
  if not f then return false end
  local n = 0
  for line in f:lines() do
    n = n + 1
    if line:find("held back: HIDDEN_LOCALES", 1, true) then
      f:close()
      -- (the stub that ships still has to be Lua the client can load)
      assert(loadfile("addon/Mealbook/Text_" .. locale .. ".lua"))
      return true
    end
    if n >= 5 then break end
  end
  f:close()
  return false
end
