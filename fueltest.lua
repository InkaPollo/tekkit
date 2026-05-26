local chamber = peripheral.wrap("ic2:reactor chamber_1")

print("Looking for items...")

-- Scan until we find the first item, then print everything about it
for i = 1, chamber.size() do
    local item = chamber.getItemMeta(i)
    if item then
        print("--- ITEM FOUND IN SLOT " .. i .. " ---")
        textutils.pagedPrint(textutils.serialize(item))
        break -- Stop after the first item
    end
end
