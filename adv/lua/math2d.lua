local M = {}

-- Put functions in this file to use them in several other scripts.
-- To get access to the functions, you need to put:
-- require "my_directory.my_file"
-- in any script using the functions.
-- Given three colinear points p, q, r, the function checks if
-- point q lies on line segment 'pr'
function M.onSegment(p,q,r)
	if(q.x <= math.max(p.x,r.x) and q.x >= math.min(p.x,r.x) and
	q.y <= math.max(p.y,r.y) and q.y>= math.min(p.y,r.y)) then
		return true
	else
		return false
	end
end

-- To find orientation of ordered triplet (p, q, r).
-- The function returns following values
-- 0 --> p, q and r are colinear
-- 1 --> Clockwise
-- 2 --> Counterclockwise
function M.orientation(p,q,r)
	val = (q.y-p.y)*(r.x-q.x)-(q.x-p.x)*(r.y-q.y)
	if(val == 0) then
		return 0
	end
	if(val > 0) then
		return 1
	else
		return 2
	end
end


-- The function that returns true if line segment 'p1q1'
-- and 'p2q2' intersect.
function M.doIntersect(p1,q1,p2,q2)
	-- Find the four orientations needed for general and
	-- special cases
	o1 = orientation(p1, q1, p2)
	o2 = orientation(p1, q1, q2)
	o3 = orientation(p2, q2, p1)
	o4 = orientation(p2, q2, q1)

	-- gerenal case (without limite case)
	if(o1 ~= o2 and o3 ~= o4) then
		return true
	end

	-- Special case
	-- p1, q1 and p2 are colinear and p2 lies on segment p1q1
	if (o1 == 0 and onSegment(p1, p2, q1)) then return true end
	-- p1, q1 and p2 are colinear and q2 lies on segment p1q1
	if (o2 == 0 and onSegment(p1, q2, q1)) then return true end
	--  p2, q2 and p1 are colinear and p1 lies on segment p2q2
	if (o3 == 0 and onSegment(p2, p1, q2)) then return true end
	-- p2, q2 and q1 are colinear and q1 lies on segment p2q2
	if (o4 == 0 and onSegment(p2, q1, q2)) then return true end
	return false; -- Doesn't fall in any of the above cases
end

-- Returns true if the point p lies inside the polygon[] with n vertices
function M.isInside(listPoints,p,h)
	-- if the point is to close to a point of the polygon
	for i=1,#listPoints do
		if(math.sqrt(math.pow(p.x-listPoints[i].x,2) + math.pow(p.y-listPoints[i].y,2))<0.4*h) then
			return false
		end
	end
	-- There must be at least 3 vertices in polygon[]
	if (#listPoints <= 3)  then return false end
	-- Create a point for line segment from p to infinite
	extreme = {x=1e05,y=p.y};
	-- Count intersections of the above line with sides of polygon
	count = 0
	for i=1,#listPoints do
		ip = (i)%(#listPoints)+1
		-- Check if the line segment from 'p' to 'extreme' intersects
		-- with the line segment from 'polygon[i]' to 'polygon[next]'
		if (doIntersect(listPoints[i], listPoints[ip], p, extreme)) then
			-- If the point 'p' is colinear with line segment 'i-ip',
			-- then check if it lies on segment. If it lies, return true,
			-- otherwise false
			if (orientation(listPoints[i], p, listPoints[ip]) == 0) then
				return onSegment(listPoints[i], p, listPoints[ip])
			end
			count = count+1
		end
	end
	-- Return true if count is odd, false otherwise
	return (count%2 == 1)
end

return M