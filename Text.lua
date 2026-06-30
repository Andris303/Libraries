local TextOffset = 0
local TextYVal = 0
local TextC = 0
local Texts = {}
local TextIds = {}
local Camera = workspace.CurrentCamera

local test = Drawing.new("Text")
test.Text = "XYZ"
test.Size = 20
test.Font = 0
TextOffset = test.TextBounds.Y
TextYVal = Camera.ViewportSize.Y - 25
test:Remove()

local function Add(id, text, color)
    if TextIds[id] then return end

    TextC += 1
    TextIds[id] = TextC
    TextYVal -= TextOffset

    Texts[id] = Drawing.new("Text")
    Texts[id].Text = text
    Texts[id].Size = 20
    Texts[id].Font = 0
    Texts[id].Position = Vector2.new(25, TextYVal)
    Texts[id].Color = color
    Texts[id].Visible = true
end

local function Remove(id)
    if not TextIds[id] then return end

    local Stack = TextIds[id]
    local temp = TextYVal

    for i, inst in pairs(TextIds) do
        if not inst then continue end
        if inst <= Stack then continue end
        TextIds[i] = inst - 1
        temp += TextOffset
        Texts[i].Position = Vector2.new(25, temp)
    end

    TextYVal += TextOffset
    TextC -= 1
    TextIds[id] = nil
    Texts[id]:Remove()
end

return {
    Add = Add,
    Remove = Remove,
}
