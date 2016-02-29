var canvas = document.getElementById('overlay');
var ctx = canvas.getContext('2d');

var animCanvas = document.getElementById('animation');
var animCtx = animCanvas.getContext('2d');

var g = 0.1;
var radius = 20;
var amplitude = 100;
var speed;
var animatingObjects = new Array();
var animatingObjectsIndex = -1;
var requestId;
var killAnimation = false;
//var cancelOnce = true;
//var path = new Array(100);
//var pathIndex = 0;
//var pathRadius = 20;
var followIndex = 0;

var percentage;
var direction = 1;
var increment;

var paths = {};

function Path(name){
    this.pathRadius = 20;
    this.pathName = name;
    this.pathIndex = 0;
    this.path = new Array(100);
}

function createPath(name) {
    //console.log("PATH NAME: " + name);
    var path = new Path(name);
    paths[name] = path;
}

function AnimationObject(object, posX, posY, endX, endY, animName, pathToFollow) {
    this.object = object;
    this.x = posX;
    this.y = posY;
    this.ex = endX;
    this.ey = endY;
    this.vx = 0;
    this.vy = 200;
    this.t0 = 0;
    this.dt;
    this.animName = animName;
    this.tempY = 0;
    this.ix = posX;
    this.iy = posY;
    this.maxSpeed = 2;
    this.maxForce = 0.06;
    this.ax = 0;
    this.ay = 0;
    this.location = createVector(this.x, this.y);
    this.velocity = createVector(this.vx, this.vy);
    this.acceleration = createVector(this.ax, this.ay);
    //this.width = object.offsetWidth * 100 / canvas.width;
    //this.height = object.offsetHeight * 100 / canvas.height;
    this.pathToFollow = pathToFollow;
    
    this.cirRadius = 25;
    this.slFactor = 1;
    this.angVel = 1;
    this.linVel = this.cirRadius * this.slFactor * this.angVel;
    this.angle = 0;
    this.timestep = 30/1000;
}

function animateObject(objectName, posX, posY, endX, endY, animName, pathToFollow) {
    //console.log("CALLING ANIMATE OBJECT");
    percentage = 0;
    increment = 0;
    
    animName = String(animName);
    pathToFollow = String(pathToFollow);
    var animationObject = new AnimationObject(objectName, posX, posY, endX, endY, animName, pathToFollow);
    
    animatingObjects.push(animationObject);
    
    animatingObjectsIndex++;
    
    animatingObjects[animatingObjectsIndex].tempY = animatingObjects[animatingObjectsIndex].y;
    animatingObjects[animatingObjectsIndex].t0 = new Date().getTime(); // initialize value of t0
    
    if (animatingObjects[animatingObjectsIndex].animName == "floatAnimation") {
        //Math.floor(Math.random()*(max-min+1)+min);
        var tempVelX = Math.floor(Math.random() * (0.5 - (-0.5) + 1) + (-0.5));
        var tempVelY = Math.floor(Math.random() * (0.5 - (-0.5) + 1) + (-0.5));
        if (tempVelX == 0) {
            tempVelX = 0.25;
        }
        else if (tempVelY == 0) {
            tempVelY = -0.25;
        }
        animatingObjects[animatingObjectsIndex].vx = tempVelX;
        animatingObjects[animatingObjectsIndex].vy = tempVelY;
    }
    else if (animatingObjects[animatingObjectsIndex].animName == "followAnimation") {
        
        animatingObjects[animatingObjectsIndex].velocity.x = animatingObjects[animatingObjectsIndex].maxSpeed;
        //animatingObjects[animatingObjectsIndex].velocity.x = 2;
        animatingObjects[animatingObjectsIndex].velocity.y = 0;
    }
    
    animFrame(animatingObjects[animatingObjectsIndex]);
    
    return;
    
}

function animFrame(object){
    //requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
    
    killAnimation = false;
    
    if(object.animName == "bounceAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        bounce(object);
    }
    else if(object.animName == "fallAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        fall(object);
    }
    else if(object.animName == "rotate90Animation")
    {
        rotate90(object);
    }
    else if(object.animName == "rotate180Animation")
    {
        rotate180(object);
    }
    else if(object.animName == "rotate270Animation")
    {
        rotate270(object);
    }
    else if(object.animName == "moveRightAndWrap")
    {
        moveRightAndWrap(object);
    }
    else if(object.animName == "moveRightAndWrapSlow")
    {
        moveRightAndWrapSlow(object);
    }
    else if(object.animName == "moveRightAndWrapSlower")
    {
        moveRightAndWrapSlower(object);
    }
    else if(object.animName == "moveLeftAndWrap")
    {
        moveLeftAndWrap(object);
    }
    else if(object.animName == "moveLeftAndCurve")
    {
        moveLeftAndCurve(object);
    }
    else if(object.animName == "moveUpAndWrap")
    {
        moveUpAndWrap(object);
    }
    else if(object.animName == "moveDownAndWrap")
    {
        moveDownAndWrap(object);
    }
    else if(object.animName == "move45DegreeAndWrap")
    {
        move45DegreeAndWrap(object);
    }
    else if(object.animName == "move135DegreeAndWrap")
    {
        move135DegreeAndWrap(object);
    }
    else if(object.animName == "move225DegreeAndWrap")
    {
        move225DegreeAndWrap(object);
    }
    else if(object.animName == "move315DegreeAndWrap")
    {
        move315DegreeAndWrap(object);
    }
    else if(object.animName == "moveToAnimation")
    {
        moveTo(object);
    }
    else if(object.animName == "shootArrowAnimation")
    {
        shootArrow(object);
    }
    else if(object.animName == "bobAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        bob(object);
    }
    else if(object.animName == "earthquakeAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        earthquake(object);
    }
    else if(object.animName == "cheerAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        cheer(object);
    }
    else if(object.animName == "floatAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        floatAnim(object);
    }
    else if(object.animName == "followAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        follow(object);
    }
    else if(object.animName == "rollAnimation")
    {
        requestId = requestAnimationFrame(function() { animFrame(object); }, canvas);
        roll(object);
    }
    else if(object.animName == "kickBall")
    {
        kickBall(object);
    }
    else if(object.animName == "skateForward")
    {
        skateForward(object);
    }
    else if(object.animName == "skateBackward")
    {
        skateBackward(object);
    }
    else if(object.animName == "rowForward")
    {
        rowForward(object);
    }
    else if(object.animName == "moveBackward")
    {
        moveBackward(object);
    }
    else if(object.animName == "pauseAnimation")
    {
        pauseAnimation(object);
    }
    else if(object.animName == "resumeAnimation")
    {
        resumeAnimation(object);
    }
    
    return;
    
}

function cancelAnimation(objectName) {
    killAnimation = true;
    
    //console.log("OBJECT: " + this.object + " NAME:" + objectName);
    //if(this.object == objectName) {
    cancelAnimationFrame(requestId);
    //}
}

function pauseAnimation(aniObject) {
    
   if(aniObject.object.className.indexOf('manipulationObject center move') > -1)
   {
       
       aniObject.object.style.WebkitAnimationPlayState = 'paused';
       //aniObject.object.className = 'manipulationObject center';//aniObject.object.className + ' paused';
   }
}

function resumeAnimation(aniObject) {
    
    if(aniObject.object.className.indexOf('manipulationObject center move') > -1)
    {
        
        aniObject.object.style.WebkitAnimationPlayState = 'running';
        //aniObject.object.className = 'manipulationObject center';//aniObject.object.className + ' paused';
    }
}


//function cancelAnimation (objectName) {
//if(cancelOnce) {
//cancelAnimationFrame(requestId);
//cancelOnce = false;
//}
//}

function bounce(aniObject) {
    var t1 = new Date().getTime(); // current time in milliseconds since midnight on 1 Jan 1970
    aniObject.dt = 0.001*(t1-aniObject.t0); // time elapsed in seconds since last call
    aniObject.t0 = t1; // reset t0
    aniObject.y = aniObject.tempY + (Math.sin(aniObject.vy) * amplitude/2) + amplitude/2;
    aniObject.object.style.top = aniObject.y + "px";
    aniObject.vy += 0.02;
}

function bounce2(object, posX, posY2) {
    posY2 = tempY + (Math.sin(speed) * amplitude/2) + amplitude/2;
    object.style.top = posY + "px";
    speed += 0.02;
    
    aniObject.y = aniObject.tempY + (Math.sin(aniObject.vy) * amplitude/2) + amplitude/2;
    aniObject.object.style.top = aniObject.y + "px";
    aniObject.vy += 0.02;
}

function fall(aniObject) {
    var t1 = new Date().getTime(); // current time in milliseconds since midnight on 1 Jan 1970
    aniObject.dt = 0.001*(t1-aniObject.t0); // time elapsed in seconds since last call
    aniObject.t0 = t1; // reset t0
    
    if (aniObject.y >= aniObject.ey){
        aniObject.vy = 0;
        cancelAnimationFrame(requestId);
    }
    else {
        aniObject.vy += g;
        aniObject.y += aniObject.vy * aniObject.dt;
    }
    
    aniObject.object.style.top = aniObject.y + "px";
}

function bob(aniObject) {
    var t1 = new Date().getTime();
    aniObject.dt = 0.001*(t1-aniObject.t0);
    var seconds = Math.round(aniObject.dt % 60);
    
    if (seconds < 4) {
        var waveHeight = Math.sin(aniObject.tempY);
        waveHeight = waveHeight/4;
        aniObject.tempY += 0.1;
        aniObject.y += waveHeight;
        aniObject.object.style.top = aniObject.y + "px";
    }
    else {
        cancelAnimationFrame(requestId);
    }
}

function earthquake(aniObject) {
    var t1 = new Date().getTime();
    aniObject.dt = 0.001*(t1-aniObject.t0);
    var seconds = Math.round(aniObject.dt % 60);
    
    if (seconds < 2.5) {
        var waveWidth = Math.sin(aniObject.tempY);
        waveWidth = waveWidth/4;
        aniObject.tempY += 0.2;
        aniObject.x += waveWidth;
        aniObject.object.style.left = aniObject.x + "px";
    }
    else {
        cancelAnimationFrame(requestId);
    }
}

function cheer(aniObject) {
    var t1 = new Date().getTime();
    aniObject.dt = 0.001*(t1-aniObject.t0);
    var seconds = Math.round(aniObject.dt % 60);
    
    if (seconds < 4) {
        var waveHeight = Math.sin(aniObject.tempY);
        aniObject.tempY += 0.1;
        aniObject.y += waveHeight;
        aniObject.object.style.top = aniObject.y + "px";
    }
    else {
        if(aniObject.y == aniObject.iy) {
            cancelAnimationFrame(requestId);
        }
    }
}

function floatAnim(aniObject) {
    //alert("Floating");
    
    //for (var i=0; i<animatingObjects.length; i++) {
    
    //separate(animatingObjects[i]);
    //velocity.add(acceleration);
    aniObject.vx += aniObject.ax;
    aniObject.vy += aniObject.ay;
    //velocity.limit(maxspeed);
    //console.log("Speed X: " + Math.max(aniObject.vx, maxSpeed));
    //console.log("Speed Y: " + Math.max(aniObject.vy, maxSpeed));
    //location.add(velocity);
    aniObject.x += aniObject.vx;
    aniObject.object.style.left = aniObject.x + "px";
    aniObject.y += aniObject.vy;
    aniObject.object.style.top = aniObject.y + "px";
    //acceleration.mult(0);
    aniObject.ax *= 0;
    aniObject.ay *= 0;
    checkEdges(aniObject);
    //}
}


function separate (aniObject) {
    var desiredSeparation = (radius-8) * 2;
    var tempX;
    var tempY;
    var sumX;
    var sumY;
    var count = 0;
    
    for (var i=0; i<animatingObjects.length; i++) {
        //var dist = Math.sqrt( Math.pow((x1-x2), 2) + Math.pow((y1-y2), 2) );
        var dist = Math.sqrt( Math.pow((aniObject.x-animatingObjects[i].x), 2) + Math.pow((aniObject.y-animatingObjects[i].y), 2) );
        //alert("Distance: " + dist);
        
        if ((dist > 0) && (dist < desiredSeparation)) {
            var diffX = aniObject.x - animatingObjects[i].x;
            var diffY = aniObject.y - animatingObjects[i].y;
            //sqrt((ax * ax) + (ay * ay) + (az * az))
            diffX = diffX / Math.sqrt(Math.pow(diffX, 2) + Math.pow(diffY, 2));
            diffY = diffY / Math.sqrt(Math.pow(diffX, 2) + Math.pow(diffY, 2));
            diffX = diffX / dist;
            diffY = diffY / dist;
            sumX += diffX;
            sumY += diffY;
            count++;
        }
    }
    
    if (count > 0) {
        sumX = sumX / Math.sqrt(Math.pow(sumX, 2) + Math.pow(sumY, 2));
        sumY = sumY / Math.sqrt(Math.pow(sumX, 2) + Math.pow(sumY, 2));
        sumX *= aniObject.maxSpeed;
        sumY *= aniObject.maxSpeed;
        //Math.max(value, maxValue)
        var steerX = sumX - aniObject.vx;
        var steerY = sumY - aniObject.vy;
        Math.max(steerX, aniObject.maxForce);
        Math.max(steerY, aniObject.maxForce);
        aniObject.ax += steerX;
        aniObject.ay += steerY;
    }
}

function checkEdges(aniObject) {
    if (aniObject.x < -5 || aniObject.x > canvas.width - 40.5) {
        aniObject.vx = -aniObject.vx;
    }
    if (aniObject.y < -5 || aniObject.y > canvas.height - 100) {
        aniObject.vy = -aniObject.vy;
    }
}

function buildPath(name, x, y) {
    //console.log("CALLING BULDPATH");
    paths[name].buildPath(x,y);
    //console.log("PATH NAME: " + name);
}

Path.prototype.buildPath = function (x, y) {
    //console.log("CALLING BULDPATH" + this.pathIndex);
    this.path[this.pathIndex] = new Array(2);
    this.path[this.pathIndex] = [parseFloat(x), parseFloat(y)];
    //console.log("X: " + x + "Y: " + y);
    this.pathIndex++;
    //console.log("PATH INDEX: " + this.pathIndex);
}

//function Path(points) {
//this.points = new Array();
//this.points = points;
//}

Path.prototype.showPath = function () {
    //console.log("Showing path...");
    ctx.lineWidth = 50;
    ctx.beginPath();
    ctx.strokeStyle = 'blue';
    ctx.moveTo(path[0][0], path[0][1]);
    for (var i = 1; i < pathIndex; i++) {
        console.log("X: " + path[i][0] + " Y: " + path[i][1]);
        ctx.lineTo(path[i][0], path[i][1]);
    }
    ctx.stroke();
}

function follow(aniObject) {
    //console.log("CALLING FOLLOW");
    var predict = aniObject.velocity.copy();
    //console.log(predict.x);
    predict.normalize();
    predict.mult(50);
    //console.log(predict.x);
    var predictLoc = add(aniObject.location, predict);
    //console.log(predictLoc.x);
    
    var normal = null;
    var target = null;
    var distanceToPath = 1000000;
    
    //console.log(paths[String(aniObject.pathToFollow)].path[0][0]);
    //console.log(Object.keys(paths));
    
    for (var i = 0; i < paths[String(aniObject.pathToFollow)].pathIndex-1; i++) {
        var a = createVector(paths[String(aniObject.pathToFollow)].path[i][0], paths[String(aniObject.pathToFollow)].path[i][1]);
        var b = createVector(paths[String(aniObject.pathToFollow)].path[i+1][0], paths[String(aniObject.pathToFollow)].path[i+1][1]);
        
        var normalPoint = getNormalPoint(predictLoc, a, b);
        //console.log(normalPoint.x);
        
        if (normalPoint.x < a.x || normalPoint.x > b.x) {
            normalPoint = b.copy();
        }
        
        var distance = dist(predictLoc, normalPoint);
        
        if (distance < distanceToPath) {
            distanceToPath = distance;
            normal = normalPoint;
            
            var dir = sub(b, a);
            dir.normalize();
            
            dir.mult(10);
            target = normalPoint.copy();
            target.add(dir);
        }
    }
    
    //console.log(paths[String(aniObject.pathToFollow)].pathRadius);
    if (distanceToPath > paths[String(aniObject.pathToFollow)].pathRadius) {
        seekAnim(target, aniObject);
    }
    
    /*
     
     //console.log("CALLING FOLLOW");
     //console.log("Vx: " + aniObject.vx + " Vy: " + aniObject.vy);
     var predictVelX = aniObject.vx;
     var predictVelY = aniObject.vy;
     
     //diffX = diffX / Math.sqrt(Math.pow(diffX, 2) + Math.pow(diffY, 2));
     predictVelX = predictVelX / Math.sqrt(Math.pow(predictVelX, 2) + Math.pow(predictVelY, 2));
     predictVelY = predictVelY / Math.sqrt(Math.pow(predictVelX, 2) + Math.pow(predictVelY, 2));
     predictVelX *= 50;
     predictVelY *= 50;
     //console.log("X: " + predictVelX + " Y: " + predictVelY);
     var predictLocX = aniObject.x + predictVelX;
     var predictLocY = aniObject.y + predictVelY;
     
     //console.log("X: " + predictLocX + " Y: " + predictLocY);
     
     var normal = new Array(2);
     var target = new Array(2);
     var distanceToPath = 1000000;
     
     //console.log("Path Index: " + pathIndex);
     for (var i = 0; i < pathIndex-1; i++) {
     
     var aX = path[i][0];
     var aY = path[i][1];
     var bX = path[i+1][0];
     var bY = path[i+1][1];
     
     var normalPoint = new Array(2);
     
     normalPoint = getNormalPoint(predictLocX, predictLocY, aX, aY, bX, bY).concat();
     
     //console.log("X: " + normalPoint[0] + " Y: " + normalPoint[1]);
     
     if (normalPoint[0] < aX || normalPoint[0] > bX) {
     normalPoint[0] = bX;
     normalPoint[1] = bY;
     }
     
     var distance = Math.sqrt(Math.pow((predictLocX-normalPoint[0]), 2) + Math.pow((predictLocY-normalPoint[1]), 2) );
     
     //console.log("Distance : " + distance);
     
     if (distance < distanceToPath) {
     distanceToPath = distance;
     normal = normalPoint.concat();
     
     var dirX = bX-aX;
     var dirY = bY-aY;
     dirX = dirX / Math.sqrt(Math.pow(dirX, 2) + Math.pow(dirY, 2));
     dirY = dirY / Math.sqrt(Math.pow(dirX, 2) + Math.pow(dirY, 2));
     
     //console.log("X: " + dirX + " Y: " + dirY);
     
     dirX *= 10;
     dirY *= 10;
     target = normalPoint.concat();
     target[0] += dirX;
     target[1] += dirY;
     
     //console.log("X: " + target[0] + " Y: " + target[1]);
     }
     }
     
     //console.log("Y ahora estoy aqui");
     
     //console.log("Distance: " + distanceToPath + "Radius: " + pathRadius);
     
     if (distanceToPath > pathRadius) {
     seekAnim(target, aniObject);
     }
     
     */
    
    aniObject.velocity.add(aniObject.acceleration);
    aniObject.velocity.limit(aniObject.maxSpeed);
    
    //aniObject.velocity.x += aniObject.acceleration.x;
    //aniObject.velocity.y += aniObject.acceleration.y;
    
    aniObject.location.x += aniObject.velocity.x;
    //aniObject.location.x = aniObject.location.x - aniObject.width / 2;
    aniObject.object.style.left = aniObject.location.x + "px";
    aniObject.location.y += aniObject.velocity.y;
    //aniObject.location.y = aniObject.location.y - aniObject.height / 2;
    aniObject.object.style.top = aniObject.location.y + "px";
    
    //console.log("X: " + aniObject.location.x + " Y: " + aniObject.location.y);
    
    aniObject.acceleration.mult(0);
    //aniObject.acceleration.x *= 0;
    //aniObject.acceleration.y *= 0;
    
    //console.log("X: " + aniObject.x + "PathX: " + path[pathIndex-1][0]);
    
    //if (aniObject.x > path[pathIndex-1][0]) {
    //cancelAnimationFrame(requestId);
    //}
    
    var groupedWithObjects = new Array();
    groupedWithObjects[0] = aniObject.object;
    
    getObjectsGroupedWithObject(aniObject.object, groupedWithObjects);
    
    //If it's grouped with other objects, move those as well.
    //Skip the object at location 1, because that's our original object that we've already moved.
    
    //for(var i = 1; i < groupedWithObjects.length; i ++) {
    groupedWithObjects[1].style.left = aniObject.location.x + "px";
    groupedWithObjects[1].style.top = aniObject.location.y + "px";
    //}
    
    //if (aniObject.location.x > path[pathIndex-1][0]) {
    //cancelAnimationFrame(requestId);
    //}
    checkEnding(aniObject);
}

function seekAnim(target, aniObject) {
    //console.log(aniObject.location);
    var desired = sub(target, aniObject.location);
    //console.log("Calling seek");
    if (desired.mag() == 0) return;
    
    desired.normalize();
    desired.mult(aniObject.maxSpeed);
    
    var steer = sub(desired, aniObject.velocity);
    steer.limit(aniObject.maxForce);
    //console.log("Calling seek");
    aniObject.acceleration.add(steer);
    
    /*
     var desiredX = target[0] - aniObject.x;
     var desiredY = target[1] - aniObject.y;
     
     if (Math.sqrt(Math.pow(desiredX, 2) + Math.pow(desiredY, 2)) == 0)
     return;
     
     desiredX = desiredX / Math.sqrt(Math.pow(desiredX, 2) + Math.pow(desiredY, 2));
     desiredY = desiredY / Math.sqrt(Math.pow(desiredX, 2) + Math.pow(desiredY, 2));
     
     desiredX *= aniObject.maxSpeed;
     desiredY *= aniObject.maxSpeed;
     
     var steerX = desiredX - aniObject.vx;
     var steerY = desiredY - aniObject.vy;
     
     aniObject.ax += steerX;
     aniObject.ay += steerY;
     */
}

function getNormalPoint(p, a ,b) {
    //console.log("Calling getNormal");
    var ap = sub(p, a);
    var ab = sub(b, a);
    ab.normalize();
    
    ab.mult(ap.dot(ab));
    var normalPoint = add(a, ab);
    return normalPoint;
    
    /*
     var apX = pX - aX;
     var apY = pY - aY;
     
     var abX = bX - aX;
     var abY = bY - aY;
     
     abX = abX / Math.sqrt(Math.pow(abX, 2) + Math.pow(abY, 2));
     abY = abY / Math.sqrt(Math.pow(abX, 2) + Math.pow(abY, 2));
     
     var ary1 = [apX, apY];
     var ary2 = [abX, abY];
     var dotProd = dot(ary1, ary2);
     abX *= dotProd;
     abY *= dotProd;
     var normalPointX = aX + abX;
     var normalPointY = aY + abY;
     var normalPoint = [normalPointX, normalPointY];
     return normalPoint;
     */
}

function dot(ary1, ary2) {
    var dotProd = 0;
    for (var i = 0; i < ary1.length; i++)
        dotProd += ary1[i] * ary2[i];
    return dotProd;
}

function checkEnding(aniObject) {
    // (x - center_x)^2 + (y - center_y)^2 < radius^2
    if (Math.pow((aniObject.location.x - paths[String(aniObject.pathToFollow)].path[paths[String(aniObject.pathToFollow)].pathIndex-1][0]),2)
        +
        Math.pow((aniObject.location.y - paths[String(aniObject.pathToFollow)].path[paths[String(aniObject.pathToFollow)].pathIndex-1][1]),2)
        <
        Math.pow(paths[String(aniObject.pathToFollow)].pathRadius,2)
        ) {
        cancelAnimationFrame(requestId);
    }
}

function roll(aniObject) {
    aniObject.location.x += aniObject.linVel * aniObject.timestep;
	aniObject.angle += aniObject.angVel * aniObject.timestep;
	animCtx.clearRect(0, 0, animCanvas.width, animCanvas.height);
	animCtx.save();
	animCtx.translate(aniObject.location.x, aniObject.location.y);
	animCtx.rotate(aniObject.angle);
	animCtx.translate(-aniObject.location.x, -aniObject.location.y);
    
    // Image width and height hard-coded for now for the lava image
    animCtx.drawImage(aniObject.object,aniObject.location.x,aniObject.location.y, 40, 40);
	animCtx.restore();
    document.getElementById('animation').style.zIndex = "100";
    checkEndingForRoll(aniObject);
}

function kickBall(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='3s';
    aniObject.object.style.webkitTransform = 'translate(480px, 0px) rotate(1440deg)';
    
}

function skateForward(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='3s';
    aniObject.object.style.WebkitTransitionTimingFunction = 'ease-out';
    aniObject.object.style.webkitTransform = 'translate(280px, 0px)';
    
}

function skateBackward(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='5s';
    aniObject.object.style.WebkitTransitionTimingFunction = 'ease-out';
    aniObject.object.style.webkitTransform = 'translate(-510px, 0px)';
    
}

function rowForward(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='5s';
    aniObject.object.style.WebkitTransitionTimingFunction = 'ease-out';
    aniObject.object.style.webkitTransform = 'translate(400px, 0px)';
    
}

function moveBackward(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='4s';
    aniObject.object.style.WebkitTransitionTimingFunction = 'ease-out';
    aniObject.object.style.webkitTransform = 'translate(-500px, 0px)';
    
}

function rotate90(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='5s';
    aniObject.object.style.WebkitTransformOrigin = 'bottom left';
    aniObject.object.style.WebkitTransform = 'translate(150px, -50px) rotate(90deg)';

}

function rotate180(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='2s';
    aniObject.object.style.webkitTransform = 'rotate(180deg)';
    
}

function rotate270(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='2s';
    aniObject.object.style.webkitTransform = 'rotate(270deg)';
    
}

function moveTopAndWrap(aniObject) {
    var keyframes = findKeyframesRule('moveTop');
    var cssStyleSheet = findCSSStyleSheet('Animations.css');
   
    // remove the existing 0% and 100% rules
    keyframes.deleteRule("0%");
    keyframes.deleteRule("100%");
    
    var top = parseFloat(aniObject.object.style.height);
    var timePerPixels =  (parseFloat(aniObject.object.style.height))/70.4;
    
    // create new 0% and 100% rules with
    keyframes.insertRule('0% {top: ' + parseFloat(aniObject.object.style.top) + 'px;}');
    keyframes.insertRule('100% {top: ' + top + 'px;}');
    
    var originalClassName = aniObject.object.className;
    
    cssStyleSheet.insertRule('.manipulationObject.center.moveTop {' + 'animation: moveTop ' + timePerPixels + 's linear 1;}');
    
    aniObject.object.className = 'manipulationObject center moveTop';
    
    timePerPixels = timePerPixels * 1000;
    
    setTimeout(function(){
        if(aniObject.object.className == "manipulationObject center moveTop")
        {
               var top = -parseFloat(aniObject.object.style.height);
               aniObject.object.style.top = 704 +  'px';
               aniObject.y = top;
               aniObject.object.className = 'manipulationObject center moveTopAndWrap';
        }
        else
        {
               console.log("Class changed to:" + aniObject.object.className);
        }
    }, timePerPixels);
}

function moveDownAndWrap(aniObject) {
    var keyframes = findKeyframesRule('moveDown');
    var cssStyleSheet = findCSSStyleSheet('Animations.css');
    
    // remove the existing 0% and 100% rules
    keyframes.deleteRule("0%");
    keyframes.deleteRule("100%");
    
    var top = parseFloat(aniObject.object.style.height);
    var timePerPixels =  (704-parseFloat(aniObject.object.style.height))/70.4;
    
    // create new 0% and 100% rules with
    keyframes.insertRule('0% {top: ' + parseFloat(aniObject.object.style.top) + 'px;}');
    keyframes.insertRule('100% {top: ' + top + 'px;}');
    
    var originalClassName = aniObject.object.className;
    
    cssStyleSheet.insertRule('.manipulationObject.center.moveDown {' + 'animation: moveDown ' + timePerPixels + 's linear 1;}');
    
    aniObject.object.className = 'manipulationObject center moveDown';
    
    timePerPixels = timePerPixels * 1000;
    
    setTimeout(function()
    {
        if(aniObject.object.className == "manipulationObject center moveDown")
        {
               var top = parseFloat(aniObject.object.style.height);
               aniObject.object.style.top = 0 +  'px';
               aniObject.y = top;
               aniObject.object.className = 'manipulationObject center moveDownAndWrap';
        }
        else
        {
               console.log("Class changed to:" + aniObject.object.className);
        }
    }, timePerPixels);

    
}

function move45DegreeAndWrap(aniObject) {
    
    var keyframes = findKeyframesRule('move45Degree');
    console.log(keyframes);
    var cssStyleSheet = findCSSStyleSheet('Animations.css');
    console.log(cssStyleSheet);
    // remove the existing 0% and 100% rules
    keyframes.deleteRule("0%");
    keyframes.deleteRule("100%");
    
    var left = 1024- parseFloat(aniObject.object.style.left);
    var top = parseFloat(aniObject.object.style.top) - 300;
    
    var hypotenuse = Math.sqrt(top*top + left*left);
    var timePerPixels =  (Math.sqrt(1024*1024+300*300) - hypotenuse)/(Math.sqrt(1024*1024+300*300)/10);
    
    // create new 0% and 100% rules with
    keyframes.insertRule('0% {left: ' + parseFloat(aniObject.object.style.left) + 'px; top: ' + parseFloat(aniObject.object.style.top) +'px; }');
    keyframes.insertRule('100% {left: ' + left + 'px;top: ' + top +'px; }');
    
    var originalClassName = aniObject.object.className;
    
    cssStyleSheet.insertRule('.manipulationObject.center.move45Degree {' + 'animation: move45Degree ' + timePerPixels + 's linear 1;}');
    
    aniObject.object.className = 'manipulationObject center move45Degree';
    
    timePerPixels = timePerPixels * 1000;
    
    setTimeout(function()
    {
        if(aniObject.object.className == "manipulationObject center move45Degree")
        {
               var left = -parseFloat(aniObject.object.style.width);
               var top = 352 + parseFloat(aniObject.object.style.height);
               aniObject.object.style.left = '0px';
               aniObject.object.style.top = '300px';
               aniObject.x = left;
               aniObject.y = top;
               aniObject.object.className = 'manipulationObject center move45DegreeAndWrap';
        }
        else
        {
               console.log("Class changed to:" + aniObject.object.className);
        }
    }, timePerPixels);
}

function moveLeftAndWrap(aniObject) {
    
    var keyframes = findKeyframesRule('moveLeft');
    console.log(keyframes);
    var cssStyleSheet = findCSSStyleSheet('Animations.css');
    console.log(cssStyleSheet);
    // remove the existing 0% and 100% rules
    keyframes.deleteRule("0%");
    keyframes.deleteRule("100%");
    
    var left = -parseFloat(aniObject.object.style.left) - parseFloat(aniObject.object.style.width);
    var timePerPixels =  (1024-parseFloat(aniObject.object.style.left))/102.4;
    
    // create new 0% and 100% rules with
    keyframes.insertRule('0% {left: ' + parseFloat(aniObject.object.style.left) + 'px;}');
    keyframes.insertRule('100% {left: ' + left + 'px;}');
    
    var originalClassName = aniObject.object.className;
    
    cssStyleSheet.insertRule('.manipulationObject.center.moveLeft {' + 'animation: moveLeft ' + timePerPixels + 's linear 1;}');
    
    aniObject.object.className = 'manipulationObject center moveLeft';
    
    timePerPixels = timePerPixels * 1000;
    
    setTimeout(function()
    {
        if(aniObject.object.className == "manipulationObject center moveLeft")
        {
               var left = -parseFloat(aniObject.object.style.width);
               aniObject.object.style.left = 1024 +  'px';
               aniObject.x = left;
               aniObject.object.className = 'manipulationObject center moveLeftAndWrap';
        }
        else
        {
               console.log("Class changed to:" + aniObject.object.className);
        }
    }, timePerPixels);
}

function moveLeftAndCurve(aniObject) {
    aniObject.object.style.WebkitTransitionDuration='5s';
    aniObject.object.style.webkitTransform = 'translate(-80px, -300px) rotate(1440deg)';
    
    setTimeout(function(){
               aniObject.object.style.WebkitTransitionDuration='3s';
               aniObject.object.style.WebkitTransitionTimingFunction = 'ease-in';
               aniObject.object.style.webkitTransform = 'translate(-140px, 205px) rotate(1800deg)';
               }, 5000);
    
}


function findKeyframesRule(rule)
{
    // gather all stylesheets into an array
    var ss = document.styleSheets;
    console.log(ss);
    
    // loop through the stylesheets
    for (var i = 0; i < ss.length; ++i) {
        
        // loop through all the rules
        for (var j = 0; j < ss[i].cssRules.length; ++j) {
            
            // find the -webkit-keyframe rule whose name matches our passed over parameter and return that rule
            if (ss[i].cssRules[j].type == window.CSSRule.WEBKIT_KEYFRAMES_RULE && ss[i].cssRules[j].name == rule)
                return ss[i].cssRules[j];
        }
    }
    
    // rule not found
    return null;
}

function findCSSStyleSheet(rule)
{
    // gather all stylesheets into an array
    var ss = document.styleSheets;
    return ss[1];
}

function moveRightAndWrap(aniObject) {
    console.log('gets here');
    var keyframes = findKeyframesRule('moveRight');
    console.log(keyframes);
    var cssStyleSheet = findCSSStyleSheet('Animations.css');
    console.log(cssStyleSheet);
    // remove the existing 0% and 100% rules
    keyframes.deleteRule("0%");
    keyframes.deleteRule("100%");
    
     var right = 1024 - parseFloat(aniObject.object.style.left);
     var timePerPixels =  (1024-parseFloat(aniObject.object.style.left))/102.4;
    
    // create new 0% and 100% rules with
    keyframes.insertRule('0% {left: ' + parseFloat(aniObject.object.style.left) + 'px;}');
    keyframes.insertRule('100% {left: ' + right + 'px;}');
    
    var originalClassName = aniObject.object.className;
    
    cssStyleSheet.insertRule('.manipulationObject.center.moveRight {' + 'animation: moveRight ' + timePerPixels + 's linear 1;}');
    
    aniObject.object.className = 'manipulationObject center moveRight';
    
    timePerPixels = timePerPixels * 1000;
    
    setTimeout(function()
    {
        if(aniObject.object.className == "manipulationObject center moveRight")
        {
               var left = -parseFloat(aniObject.object.style.width);
               aniObject.object.style.left = left +  'px';
               aniObject.x = left;
               aniObject.object.className = 'manipulationObject center moveRightAndWrap';
        }
        else
        {
                console.log("Class changed to:" + aniObject.object.className);
        }
    }, timePerPixels);
}

function moveRightAndWrapSlow(aniObject) {
    
    var keyframes = findKeyframesRule('moveRightSlow');
    console.log(keyframes);
    var cssStyleSheet = findCSSStyleSheet('Animations.css');
    console.log(cssStyleSheet);
    // remove the existing 0% and 100% rules
    keyframes.deleteRule("0%");
    keyframes.deleteRule("100%");
    
    var right = 1024 - parseFloat(aniObject.object.style.left);
    var timePerPixels =  (1024-parseFloat(aniObject.object.style.left))/68.266;
    console.log(timePerPixels)
    
    // create new 0% and 100% rules with
    keyframes.insertRule('0% {left: ' + parseFloat(aniObject.object.style.left) + 'px;}');
    keyframes.insertRule('100% {left: ' + right + 'px;}');
    
    var originalClassName = aniObject.object.className;
    
    cssStyleSheet.insertRule('.manipulationObject.center.moveRightSlow {' + 'animation: moveRightSlow ' + timePerPixels + 's linear 1;}');
    
    aniObject.object.className = 'manipulationObject center moveRightSlow';
    
    timePerPixels = timePerPixels * 1000;
    
    setTimeout(function(){
            if(aniObject.object.className == "manipulationObject center moveRightSlow")
            {
               var left = -parseFloat(aniObject.object.style.width);
               aniObject.object.style.left = left +  'px';
               aniObject.x = left;
               aniObject.object.className = 'manipulationObject center moveRightAndWrapSlow';
            }
            else
            {
               console.log("Class changed to:" + aniObject.object.className);
            }
    }, timePerPixels);
}

function moveRightAndWrapSlower(aniObject) {
    
    var keyframes = findKeyframesRule('moveRightSlower');
    console.log(keyframes);
    var cssStyleSheet = findCSSStyleSheet('Animations.css');
    console.log(cssStyleSheet);
    // remove the existing 0% and 100% rules
    keyframes.deleteRule("0%");
    keyframes.deleteRule("100%");
    
    var right = 1024 - parseFloat(aniObject.object.style.left);
    var timePerPixels =  (1024-parseFloat(aniObject.object.style.left))/51.2;
    console.log(timePerPixels);
    
    // create new 0% and 100% rules with
    keyframes.insertRule('0% {left: ' + parseFloat(aniObject.object.style.left) + 'px;}');
    keyframes.insertRule('100% {left: ' + right + 'px;}');
    
    var originalClassName = aniObject.object.className;
    
    cssStyleSheet.insertRule('.manipulationObject.center.moveRightSlower {' + 'animation: moveRightSlower ' + timePerPixels + 's linear 1;}');
    
    aniObject.object.className = 'manipulationObject center moveRightSlower';
    
    timePerPixels = timePerPixels * 1000;
    
    setTimeout(function(){
        if(aniObject.object.className == "manipulationObject center moveRightSlower")
        {
               var left = -parseFloat(aniObject.object.style.width);
               aniObject.object.style.left = left +  'px';
               aniObject.x = left;
               aniObject.object.className = 'manipulationObject center moveRightAndWrapSlower';
        }
        else
        {
               console.log("Class changed to:" + aniObject.object.className);
        }
    }, timePerPixels);
}

//
function moveTo(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='4s';
    aniObject.object.style.webkitTransform = 'translate(-280px, 158px)';
    
}

function shootArrow(aniObject) {
    
    aniObject.object.style.WebkitTransitionDuration='4s';
    aniObject.object.style.webkitTransform = 'translate(-600px, 30px)';
    
}


function checkEndingForRoll(aniObject) {
    // The ending value is hard-coded for now, it should be gotten from the ending waypoint for the object
    if(aniObject.location.x > 1000) {
        //aniObject.location.x = aniObject.ix;
        //aniObject.location.y = aniObject.iy;
        cancelAnimationFrame(requestId);
    }
}

// Debug
// Use console.log(message); message is of type string
console = new Object();

console.log = function(log) {
    var iframe = document.createElement("IFRAME");
    iframe.setAttribute("src", "ios-log:#iOS#" + log);
    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
};

console.debug = console.log;
console.info = console.log;
console.warn = console.log;
console.error = console.log;