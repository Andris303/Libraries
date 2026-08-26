-- Credits to IAMPR1ME

local Convex = {
    Scratch = {
        Points = {},
        Hull = {},
        Poly = {}
    },

    Static = {
        HWMPoints = 0,
        HWMHull = 0,
        HWMPoly = 0
    }
}

local function TruncateBuffer(Buffer, NewSize, HighWaterMark)
    for Index = NewSize + 1, HighWaterMark do
        Buffer[Index] = nil
    end
    return math.max(NewSize, HighWaterMark)
end

local function CrossDimension(OriginX, OriginY, PointAX, PointAY, PointBX, PointBY)
    return (PointAX - OriginX) * (PointBY - OriginY) - (PointAY - OriginY) * (PointBX - OriginX)
end

local function CalculateConvexHull(Points, PointCount, Outer)
    if PointCount == 0 then return 0 end
    if PointCount == 1 then Outer[1] = Points[1]; return 1 end
    if PointCount == 2 then Outer[1] = Points[1]; Outer[2] = Points[2]; return 2 end
    table.sort(Points, function(PointA, PointB)
        return PointA.X < PointB.X or (PointA.X == PointB.X and PointA.Y < PointB.Y)
    end)
    local Size = 0
    for Index = 1, PointCount do
        local Point = Points[Index]
        while Size >= 2 and CrossDimension(Outer[Size - 1].X, Outer[Size - 1].Y, Outer[Size].X, Outer[Size].Y, Point.X, Point.Y) <= 0 do
            Size = Size - 1
        end
        Size = Size + 1
        Outer[Size] = Point
    end
    local LowerHullSize = Size
    for Index = PointCount - 1, 1, -1 do
        local Point = Points[Index]
        while Size > LowerHullSize and CrossDimension(Outer[Size - 1].X, Outer[Size - 1].Y, Outer[Size].X, Outer[Size].Y, Point.X, Point.Y) <= 0 do
            Size = Size - 1
        end
        Size = Size + 1
        Outer[Size] = Point
    end
    return Size - 1
end

local function ProjectPartCorners(Part, WriteOffset)
    local PositionX = Part.Position.X
    local PositionY = Part.Position.Y
    local PositionZ = Part.Position.Z
    local HalfSizeX = Part.Size.X * 0.5
    local HalfSizeY = Part.Size.Y * 0.5
    local HalfSizeZ = Part.Size.Z * 0.5
    local RightVector = Part.RightVector
    local UpVector = Part.UpVector
    local LookVector = Part.LookVector
    local RightX = RightVector.X * HalfSizeX
    local RightY = RightVector.Y * HalfSizeX
    local RightZ = RightVector.Z * HalfSizeX
    local UpX = UpVector.X * HalfSizeY
    local UpY = UpVector.Y * HalfSizeY
    local UpZ = UpVector.Z * HalfSizeY
    local LookX = LookVector.X * HalfSizeZ
    local LookY = LookVector.Y * HalfSizeZ
    local LookZ = LookVector.Z * HalfSizeZ
    local SignR = 1
    for _ = 1, 2 do
        local SignU = 1
        for _ = 1, 2 do
            local SignL = 1
            for _ = 1, 2 do
                local WorldPoint = Vector3.new(
                    PositionX + SignR * RightX + SignU * UpX + SignL * LookX,
                    PositionY + SignR * RightY + SignU * UpY + SignL * LookY,
                    PositionZ + SignR * RightZ + SignU * UpZ + SignL * LookZ
                )
                local ScreenPoint, OnScreen = workspace.CurrentCamera:WorldToScreenPoint(WorldPoint)
                if OnScreen then
                    WriteOffset = WriteOffset + 1
                    local Slot = Convex.Scratch.Points[WriteOffset]
                    if Slot then
                        Slot.X = ScreenPoint.X
                        Slot.Y = ScreenPoint.Y
                    else
                        Convex.Scratch.Points[WriteOffset] = {X = ScreenPoint.X, Y = ScreenPoint.Y}
                    end
                end
                SignL = -1
            end
            SignU = -1
        end
        SignR = -1
    end
    return WriteOffset
end

local function DrawPolygon(Hull, Size, Color, Opacity)
    if Size < 3 then return end
    local Pivot = Vector2.new(Hull[1].X, Hull[1].Y)
    for Index = 2, Size - 1 do
        DrawingImmediate.FilledTriangle(Pivot, Vector2.new(Hull[Index].X, Hull[Index].Y), Vector2.new(Hull[Index + 1].X, Hull[Index + 1].Y), Color, Opacity)
    end
end

local GROUP_EPSILON = 0.0001
local GROUP_JOIN_EPSILON = 0.75

local function PolygonArea(Poly)
    local Area = 0
    local Count = #Poly

    for Index = 1, Count do
        local A = Poly[Index]
        local B = Poly[Index % Count + 1]

        Area += A.X * B.Y - B.X * A.Y
    end

    return Area * 0.5
end

local function ReversePolygon(Poly)
    local Left = 1
    local Right = #Poly

    while Left < Right do
        Poly[Left], Poly[Right] = Poly[Right], Poly[Left]

        Left += 1
        Right -= 1
    end
end

local function ExpandPolygon(Poly, Padding)
    if not Padding or Padding <= 0 then
        return
    end

    local CenterX = 0
    local CenterY = 0

    for _, Point in Poly do
        CenterX += Point.X
        CenterY += Point.Y
    end

    CenterX /= #Poly
    CenterY /= #Poly

    for _, Point in Poly do
        local DX = Point.X - CenterX
        local DY = Point.Y - CenterY
        local Length = math.sqrt(DX * DX + DY * DY)

        if Length > 0 then
            Point.X += DX / Length * Padding
            Point.Y += DY / Length * Padding
        end
    end
end

local function ProjectPartPolygon(Part, Padding)
    local PointCount = ProjectPartCorners(Part, 0)

    Convex.Static.HWMPoints = TruncateBuffer(
        Convex.Scratch.Points,
        PointCount,
        Convex.Static.HWMPoints
    )

    if PointCount < 3 then
        return nil
    end

    local Size = CalculateConvexHull(
        Convex.Scratch.Points,
        PointCount,
        Convex.Scratch.Hull
    )

    Convex.Static.HWMHull = TruncateBuffer(
        Convex.Scratch.Hull,
        Size,
        Convex.Static.HWMHull
    )

    if Size < 3 then
        return nil
    end

    local Poly = {}

    for Index = 1, Size do
        local Point = Convex.Scratch.Hull[Index]

        Poly[Index] = {
            X = Point.X,
            Y = Point.Y
        }
    end

    -- Make every polygon counter-clockwise.
    if PolygonArea(Poly) < 0 then
        ReversePolygon(Poly)
    end

    ExpandPolygon(Poly, Padding)

    return Poly
end

local function PointInsideConvex(Point, Poly)
    for Index = 1, #Poly do
        local A = Poly[Index]
        local B = Poly[Index % #Poly + 1]

        if CrossDimension(
            A.X,
            A.Y,
            B.X,
            B.Y,
            Point.X,
            Point.Y
        ) < -GROUP_EPSILON then
            return false
        end
    end

    return true
end

local function SegmentIntersectionT(A, B, C, D)
    local RX = B.X - A.X
    local RY = B.Y - A.Y

    local SX = D.X - C.X
    local SY = D.Y - C.Y

    local Denominator = RX * SY - RY * SX

    if math.abs(Denominator) <= GROUP_EPSILON then
        return nil
    end

    local QX = C.X - A.X
    local QY = C.Y - A.Y

    local T = (QX * SY - QY * SX) / Denominator
    local U = (QX * RY - QY * RX) / Denominator

    if
        T > GROUP_EPSILON
        and T < 1 - GROUP_EPSILON
        and U >= -GROUP_EPSILON
        and U <= 1 + GROUP_EPSILON
    then
        return T
    end

    return nil
end

local function LerpPoint(A, B, T)
    return {
        X = A.X + (B.X - A.X) * T,
        Y = A.Y + (B.Y - A.Y) * T
    }
end

local function BuildBoundarySegments(Polygons)
    local Boundary = {}

    for PolygonIndex, Poly in Polygons do
        for EdgeIndex = 1, #Poly do
            local A = Poly[EdgeIndex]
            local B = Poly[EdgeIndex % #Poly + 1]

            local Splits = {0, 1}

            -- Find every point where another body part
            -- intersects this polygon edge.
            for OtherIndex, Other in Polygons do
                if OtherIndex ~= PolygonIndex then
                    for OtherEdgeIndex = 1, #Other do
                        local C = Other[OtherEdgeIndex]
                        local D = Other[OtherEdgeIndex % #Other + 1]

                        local T = SegmentIntersectionT(A, B, C, D)

                        if T then
                            Splits[#Splits + 1] = T
                        end
                    end
                end
            end

            table.sort(Splits)

            -- Remove duplicate split values.
            local CleanSplits = {}

            for _, T in Splits do
                if
                    #CleanSplits == 0
                    or math.abs(T - CleanSplits[#CleanSplits]) > GROUP_EPSILON
                then
                    CleanSplits[#CleanSplits + 1] = T
                end
            end

            for SplitIndex = 1, #CleanSplits - 1 do
                local T1 = CleanSplits[SplitIndex]
                local T2 = CleanSplits[SplitIndex + 1]

                if T2 - T1 <= GROUP_EPSILON then
                    continue
                end

                local Mid = LerpPoint(A, B, (T1 + T2) * 0.5)

                local Covered = false

                -- If this section of the edge is inside another
                -- body part, it is an internal edge and shouldn't
                -- be outlined.
                for OtherIndex, Other in Polygons do
                    if
                        OtherIndex ~= PolygonIndex
                        and PointInsideConvex(Mid, Other)
                    then
                        Covered = true
                        break
                    end
                end

                if not Covered then
                    Boundary[#Boundary + 1] = {
                        A = LerpPoint(A, B, T1),
                        B = LerpPoint(A, B, T2)
                    }
                end
            end
        end
    end

    return Boundary
end

local function SamePoint(A, B)
    local DX = A.X - B.X
    local DY = A.Y - B.Y

    return DX * DX + DY * DY
        <= GROUP_JOIN_EPSILON * GROUP_JOIN_EPSILON
end

local function StitchBoundary(Segments)
    local Loops = {}
    local Used = {}

    for StartIndex, StartSegment in Segments do
        if Used[StartIndex] then
            continue
        end

        Used[StartIndex] = true

        local Loop = {
            StartSegment.A,
            StartSegment.B
        }

        local StartPoint = StartSegment.A
        local CurrentPoint = StartSegment.B

        local Guard = 0

        while
            not SamePoint(CurrentPoint, StartPoint)
            and Guard <= #Segments
        do
            Guard += 1

            local Found = false

            for Index, Segment in Segments do
                if Used[Index] then
                    continue
                end

                if SamePoint(Segment.A, CurrentPoint) then
                    Used[Index] = true

                    Loop[#Loop + 1] = Segment.B
                    CurrentPoint = Segment.B

                    Found = true
                    break
                elseif SamePoint(Segment.B, CurrentPoint) then
                    -- Should rarely be necessary because all polygons
                    -- are CCW, but makes stitching more robust.
                    Used[Index] = true

                    Loop[#Loop + 1] = Segment.A
                    CurrentPoint = Segment.A

                    Found = true
                    break
                end
            end

            if not Found then
                break
            end
        end

        if
            #Loop >= 4
            and SamePoint(Loop[#Loop], StartPoint)
        then
            Loop[#Loop] = nil

            if #Loop >= 3 then
                Loops[#Loops + 1] = Loop
            end
        end
    end

    return Loops
end

local function HighlightGroup(
    Parts,
    color,
    opacityFill,
    opacityOutline,
    Thickness,
    MergePadding
)
    MergePadding = MergePadding or 1.25

    local Polygons = {}

    for _, Part in Parts do
        if not Part or not Part.Parent then
            continue
        end

        local Success, Poly = pcall(
            ProjectPartPolygon,
            Part,
            MergePadding
        )

        if Success and Poly then
            Polygons[#Polygons + 1] = Poly

            -- Each part is convex, so the existing fan-fill
            -- remains valid.
            if opacityFill and opacityFill > 0 then
                DrawPolygon(
                    Poly,
                    #Poly,
                    color,
                    opacityFill
                )
            end
        end
    end

    if #Polygons == 0 then
        return
    end

    if #Polygons == 1 then
        DrawOutline(
            Polygons[1],
            #Polygons[1],
            color,
            opacityOutline,
            Thickness
        )

        return
    end

    local Segments = BuildBoundarySegments(Polygons)
    local Loops = StitchBoundary(Segments)

    if #Loops == 0 then
        -- Safety fallback.
        for _, Poly in Polygons do
            DrawOutline(
                Poly,
                #Poly,
                color,
                opacityOutline,
                Thickness
            )
        end

        return
    end

    for _, Loop in Loops do
        DrawOutline(
            Loop,
            #Loop,
            color,
            opacityOutline,
            Thickness
        )
    end
end

local function DrawOutline(Hull, Size, Color, Opacity, Thickness)
    if Size < 2 then return end
    for Index = 1, Size do
        local Entry = Hull[Index]
        Convex.Scratch.Poly[Index] = Vector2.new(Entry.X, Entry.Y)
    end
    Convex.Scratch.Poly[Size + 1] = Vector2.new(Hull[1].X, Hull[1].Y)
    Convex.Scratch.Poly[Size + 2] = nil
    if Size + 1 < Convex.Static.HWMPoly then
        for Index = Size + 2, Convex.Static.HWMPoly do
            Convex.Scratch.Poly[Index] = nil
        end
    end
    Convex.Static.HWMPoly = math.max(Convex.Static.HWMPoly, Size + 1)
    DrawingImmediate.Polyline(Convex.Scratch.Poly, Color, Opacity, Thickness)
end

local function Highlight(inst, color, opacityFill, opacityOutline, Thickness)
    local PointCount = 0
    PointCount = ProjectPartCorners(inst, PointCount)
    Convex.Static.HWMPoints = TruncateBuffer(Convex.Scratch.Points, PointCount, Convex.Static.HWMPoints)
    local Size = CalculateConvexHull(Convex.Scratch.Points, PointCount, Convex.Scratch.Hull)
    Convex.Static.HWMHull = TruncateBuffer(Convex.Scratch.Hull, Size, Convex.Static.HWMHull)
    DrawPolygon(Convex.Scratch.Hull, Size, color, opacityFill)
    DrawOutline(Convex.Scratch.Hull, Size, color, opacityOutline, Thickness)
end

local h = {
    Highlight = Highlight,
    HighlightGroup = HighlightGroup
}
