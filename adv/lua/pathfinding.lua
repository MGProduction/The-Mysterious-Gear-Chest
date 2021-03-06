local M = {}

--[[
Shortest Path Through A Concave Polygon With Holes

- Works with a bounding polygon that is either a convex polygon or a concave polygon.

- Other polygons can be placed within the bounding polygon to create “holes” — 
interior polygons of exclusion.

- Self-intersection complex polygons are not considered by the algorithm.

References:
- http://developer.coronalabs.com/node/25249 (the article from where the lua code is taken and adapted)
- http://alienryderflex.com/shortest_path/ (The C code source for this Lua code)
- http://code.google.com/p/icecream-sandwich/source/browse/trunk/+icecream-sandwich/src/se/mushroomwars/mapeditor/model/PathFinder.java?spec=svn52&r=52
- http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm
- http://www.mathopenref.com/polygonconcave.html
- http://renaud.waldura.com/doc/java/dijkstra/
- http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
- http://en.wikipedia.org/wiki/Breadth-first_search
--]]


-- PathFinding
local sqrt	= math.sqrt
local abs	= math.abs
local eps = 1e-11
-- (larger than total solution dist could ever be)
local INF = math.huge

local function calcDist( sX, sY, eX, eY)
	dX = eX - sX
	dY = eY - sY
	return sqrt( dX * dX + dY * dY )
end

local function getZero(x)
	return abs(x) <= eps and 0 or x
end

local function getLipsCache(testSX,testSY,testEX,testEY, lipsCache)	
	for _,o in ipairs(lipsCache) do
		if o[1] == testSX and o[2] == testSY and o[3] == testEX and o[4] == testEY then
			--print("lipsCache used")
			return o
		end
	end
	local cacheObj = {testSX, testSY, testEX, testEY}
	lipsCache[#lipsCache+1] = cacheObj
	return cacheObj
end

function moveTo(a,b,n,pdx,pdy)
	local dx=a.x-b.x
	local dy=a.y-b.y
	local len=math.sqrt(dx*dx+dy*dy)
	local angle=math.atan2(dy, dx)
	local cosa=math.cos(angle)*pdx
	local sina=math.sin(angle)*pdy
	n.x=a.x-cosa
	n.y=a.y-sina
end

--http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
function M.pointInPolygonSet( x, y, allPolys )
	local oddNodes = false
	local polyI, i, j
	for polyI=1, #allPolys do
		local poly = allPolys[polyI].points
		j = #poly
		for i=1, #poly do
			if ((poly[i].y > y) ~= (poly[j].y > y)) then
				if (x < (poly[j].x - poly[i].x) * (y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x) then
					oddNodes = not oddNodes
				end
			end
			j = i
		end
	end
	return oddNodes
end

--[[
This function should be called with the full set of *all* relevant polygons.
	(The algorithm automatically knows that enclosed polygons are "no-go"
	areas.)

	Note:	As much as possible, this algorithm tries to return YES when the
	test line-segment is exactly on the border of the polygon, particularly
	if the test line-segment *is* a side of a polygon.
	--]]
	function lineInPolygonSet( testSX, testSY, testEX, testEY, allPolys)

		local theCos, theSin, dist, sX, sY, eX, eY, rotSX, rotSY, rotEX, rotEY, crossX
		local i, j, polyI
		local origTestEX, origTestEY = testEX, testEY

		testEX = testEX - testSX
		testEY = testEY - testSY
		dist = sqrt( testEX * testEX + testEY * testEY )
		theCos = testEX / dist
		theSin = testEY / dist

		for polyI=1, #allPolys do
			local poly = allPolys[polyI].points
			for i=1, #poly do
				j = i + 1
				if (j > #poly) then
					j = 1
				end

				sX = poly[i].x - testSX
				sY = poly[i].y - testSY
				eX = poly[j].x - testSX
				eY = poly[j].y - testSY

				if (sX == 0 and sY == 0 and eX == testEX and eY == testEY or eX == 0 and eY == 0 and sX == testEX and sY == testEY) then
					return true
				end

				rotSX = getZero(sX * theCos + sY * theSin)
				rotSY = getZero(sY * theCos - sX * theSin)
				rotEX = getZero(eX * theCos + eY * theSin)
				rotEY = getZero(eY * theCos - eX * theSin)
				crossX = getZero(rotSX + (rotEX-rotSX)*(0-rotSY)/(rotEY-rotSY))

				if (rotSY < 0 and rotEY > 0 or rotEY < 0 and rotSY > 0) then
					if (crossX >= 0 and crossX <= dist) then
						return false
					end
				end

				if (rotSY == 0 and rotEY == 0 and (rotSX >= 0 or rotEX >= 0) and (rotSX <= dist or rotEX <= dist)
				and (rotSX < 0 or rotEX < 0 or rotSX > dist or rotEX > dist)) then
					return false
				end
			end
		end

		return M.pointInPolygonSet( testSX + testEX / 2, testSY + testEY / 2, allPolys )
	end

	--[[
	Finds the shortest path from sX,sY to eX,eY that stays within the polygon set.
	Note:  To be safe, the solutionX and solutionY arrays should be large enough
	to accommodate all the corners of your polygon set (although it is
	unlikely that anywhere near that many elements will ever be needed).

	Returns YES if the optimal solution was found, or NO if there is no solution.
	If a solution was found, solutionX and solutionY will contain the coordinates
	of the intermediate nodes of the path, in order.  (The startpoint and endpoint
	are assumed, and will not be included in the solution.)

	If a waypointList is passed it used to calculate path and use polygons only as boundaries/blocked regions
	If a waypointList is not provided it uses all the polygons vertex as available points for path finding
	--]]
	function shortestPath( sX, sY, eX, eY, allPolys, waypointList)
		local solutionNodes, solutions = 0, {}
		-- (enough for all polycorners plus two)
		local pointList = {} 
		local treeCount, polyI, i, j, bestI, bestJ
		local bestDist, newDist

		-- Fail if either the startpoint or endpoint is outside the polygon set.
		if not M.pointInPolygonSet(sX,sY,allPolys) then
			return false
		end
		if not M.pointInPolygonSet(eX,eY,allPolys) then
			return false
		end

		-- If there is a straight-line solution, return with it immediately.
		if lineInPolygonSet(sX,sY,eX,eY,allPolys) then
			solutionNodes = 0
			return true
		end

		-- Build a point list that refers to the corners of the
		-- polygons, as well as to the startpoint and endpoint.
		-- Set the initial totalDist to INF.
		pointList[1] = {x=sX,y=sY,prev=0,totalDist=INF}
		if waypointList then
			for i=1, #waypointList do
				pointList[#pointList+1] = {x=waypointList[i].x, y=waypointList[i].y, prev=0, totalDist=INF}
			end
		else
			for polyI=1, #allPolys do
				local poly = allPolys[polyI].points
				for i=1, #poly do
					pointList[#pointList+1] = {x=poly[i].x, y=poly[i].y, prev=0, totalDist=INF}
				end
			end
		end
		pointList[#pointList+1] = {x=eX,y=eY,prev=0,totalDist=INF}

		-- Initialize the shortest-path tree to include just the startpoint.
		treeCount = 1
		pointList[1].totalDist = 0
		bestJ = 1

		--used to optimize the 'lineInPolygonSet / calcDist' loop
		local lipsCache = {}
		while (bestJ < #pointList) do
			bestDist = INF
			for i = 1, treeCount do
				for j = treeCount, #pointList do
					local cacheObj = getLipsCache(pointList[i].x, pointList[i].y, pointList[j].x, pointList[j].y, lipsCache)
					if cacheObj.result == nil then
						cacheObj.result = lineInPolygonSet( pointList[i].x, pointList[i].y, pointList[j].x, pointList[j].y, allPolys )
						if cacheObj.result then
							cacheObj.dist = calcDist( pointList[i].x, pointList[i].y, pointList[j].x, pointList[j].y)
						end
					end
					if cacheObj.result then
						newDist = pointList[i].totalDist + cacheObj.dist
						if (newDist < bestDist) then
							bestDist = newDist
							bestI = i
							bestJ = j
						end
					end
				end
			end
			-- (no solution)
			if (bestDist == INF) then
				return false  
			end

			pointList[bestJ].prev = bestI
			pointList[bestJ].totalDist = bestDist
			local tmp = pointList[bestJ]
			pointList[bestJ] = pointList[treeCount]
			pointList[treeCount] = tmp

			treeCount = treeCount + 1
		end

		--print('Exited while loop with final pointList results')

		--print the final pointList results for debugging   --bm--
		--[[
		local m
		for m=1, #pointList do
			print('point ',m,pointList[m].x, pointList[m].y, pointList[m].prev, pointList[m].totalDist)
		end
		print()
		--]]

		-- Load the solution arrays.
		--this initial value will exclude the start point as a solution point
		solutionNodes = - 1
		--start at this index
		i = treeCount - 1  
		local nodeLimit = 0
		--limit solutionNodes count to an arbitrary value
		while (i > 1 and nodeLimit < 1000) do  
			nodeLimit = nodeLimit + 1
			i = pointList[i].prev
			solutionNodes = solutionNodes + 1
			--print(i)
		end

		--this is the number of internal points
		--print("solutionNodes = "..solutionNodes)  
		--print()
		center=vmath.vector3()
		cnt=0
		for polyI=1, #allPolys do
			local poly = allPolys[polyI].points
			for i=1, #poly do
				center.x=center.x+poly[i].x
				center.y=center.y+poly[i].y
				cnt=cnt+1
			end			
		end	
		center.x=center.x/cnt	
		center.y=center.y/cnt

		j = solutionNodes
		i = treeCount - 1
		while (j > 0) do
			i = pointList[i].prev			
			local px=pointList[i].x
			local py=pointList[i].y
			if 0==1 then
				local np=vmath.vector3()
				moveTo(pointList[i],center,np,32,8)
				px=np.x
				py=np.y
			end
			solutions[ j ] = { x=px, y=py }
			j = j - 1
		end

		-- Success.
		return true, solutions
	end

	function M.findPath(startpath, endpath, polys, waypointList)
		--local x = os.clock()
		local result, points = shortestPath( startpath.x, startpath.y, endpath.x, endpath.y, polys, waypointList )
		--print(result, points)
		--print(string.format("elapsed time: %.2f\n", os.clock() - x))
		return result, points
	end 

	function findLineIntersection (s1, e1, s2, e2)
		local d = (s1.x - e1.x) * (s2.y - e2.y) - (s1.y - e1.y) * (s2.x - e2.x)
		if (d == 0) then return nil end
		local a = s1.x * e1.y - s1.y * e1.x
		local b = s2.x * e2.y - s2.y * e2.x
		local x = (a * (s2.x - e2.x) - (s1.x - e1.x) * b) / d
		local y = (a * (s2.y - e2.y) - (s1.y - e1.y) * b) / d
		if (x < math.min(s1.x,e1.x) or x > math.max(s1.x,e1.x)) then return nil end
		if (x < math.min(s2.x,e2.x) or x > math.max(s2.x,e2.x)) then return nil end
		if (y < math.min(s1.y,e1.y) or y > math.max(s1.y,e1.y)) then return nil end
		if (y < math.min(s2.y,e2.y) or y > math.max(s2.y,e2.y)) then return nil end
		return vmath.vector3(x, y,0)
	end

	function oldfindLineIntersection(start1, end1, start2, end2)
		local x1,y1,x2,y2,x3,y3,x4,y4 = start1.x, start1.y, end1.x, end1.y, start2.x, start2.y, end2.x, end2.y
		local d = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
		if (d == 0) then return nil end

		local xi = ((x3-x4)*(x1*y2-y1*x2)-(x1-x2)*(x3*y4-y3*x4))/d
		local yi = ((y3-y4)*(x1*y2-y1*x2)-(y1-y2)*(x3*y4-y3*x4))/d

		if x1~=x2 and (xi <= math.min(x1,x2) or xi >= math.max(x1,x2)) then return nil end
		if x3~=x4 and (xi <= math.min(x3,x4) or xi >= math.max(x3,x4)) then return nil end
		return vmath.vector3(xi,yi,0)
	end

	function M.findLimit(startpath,endpath,allPolys)
		local bestfnd=nil
		local bestlen=10000000
		for polyI=1, #allPolys do
			local poly = allPolys[polyI].points
			for i=1, #poly-1 do
				local fnd=findLineIntersection(startpath,endpath,poly[i],poly[i+1])
				if fnd==nil then
				else					
					local dx=startpath.x-fnd.x
					local dy=startpath.y-fnd.y
					local len=math.sqrt(dx*dx+dy*dy)
					if len<bestlen then
						bestfnd=fnd
						bestlen=len
						if 1==1 then
							local angle=math.atan2(dy, dx)
							local cosa=math.cos(angle)*math.max(0,len-8)
							local sina=math.sin(angle)*math.max(0,len-8)
							bestfnd.x=startpath.x-cosa
							bestfnd.y=startpath.y-sina
						end
					end
				end
			end
		end		
		return bestfnd
	end

return M