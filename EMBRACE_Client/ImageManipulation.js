var groupings = new Array(); //Stores objects that may be grouped together. 3 or more objects may be grouped at different times.
var overlayGraphics = new jsGraphics(document.getElementById('overlay')); //Create jsGraphics object

/*
 * Moves the specified object to the new X,Y coordinated.
 * Also checks to see if this particular object is grouped to other objects.
 * If it is, all other objects it's grouped to are also moved.
 * This includes objects that are grouped to objects that it is grouped to. (recursive)
 */
function moveObject(object, newX, newY) {
    if(object == null)
        alert("object is null");
    
    //Calculate a delta change, so we know what to move grouped objects by.
    var deltaX = newX - object.offsetLeft;
    var deltaY = newY - object.offsetTop;
    
    //Move the object to the new location.
    object.style.left = newX + "px";
    object.style.top = newY + "px";
    
    //Get objects this object may be grouped with.
    var groupedWithObjects = new Array();
    groupedWithObjects[0] = object; //If we don't do this the original object will be added in the recursive method.
    
    getObjectsGroupedWithObject(object, groupedWithObjects);
    
    //If it's grouped with other objects, move those as well.
    //Skip the object at location 1, because that's our original object that we've already moved.
    for(var i = 1; i < groupedWithObjects.length; i ++) {        
        groupedWithObjects[i].style.left = groupedWithObjects[i].offsetLeft + deltaX + "px";
        groupedWithObjects[i].style.top =  groupedWithObjects[i].offsetTop + deltaY + "px";
    }
    
    //Check to see if any of the objects in this group are overlapping with any other objects that they are not grouped with.
    //If so, go ahead and highlight those objects.
    //Also make sure to remove highlighting of objects that should no longer be highlighted.
    //clearAllHighlighted();
    clearCanvas(); 
    
    /*for(var i = 0; i < groupedWithObjects.length; i ++) {
        var overlapArray = checkObjectOverlap(groupedWithObjects[i]);
    
        for(i = 0; i < overlapArray.length; i ++) {
            highlight(overlapArray[i][1]);
        }
    }*/

    //if(groupings.length > 0)
    //    alert("object: " + object.id);
}

/* 
 * Function finds whether two objects are overlapping. 
 * If they are, then it adds them as a group to the groupings array.
 */
/*function checkObjectOverlap(object) {
    //Check to see if object with object is overlapping any other object that it can be grouped with.
    var manipulationObjects = document.getElementsByClassName('manipulationObject');

    for(var i = 0; i < manipulationObjects.length; i++) { //go through all manipulationObjects, checking for overlap.
        if(object.id != manipulationObjects[i].id) { //Don't check the object you're moving against itself.
            //check to see if objects overlap. If they do, add the object to the array.
            if((object.offsetLeft + object.offsetWidth > manipulationObjects[i].offsetLeft) && (object.offsetLeft < manipulationObjects[i].offsetLeft + manipulationObjects[i].offsetWidth) && (object.offsetTop + object.offsetHeight > manipulationObjects[i].offsetTop) && (object.offsetTop < manipulationObjects[i].offsetTop + manipulationObjects[i].offsetHeight)) {

                //check to see if the 2 are already grouped together
                var areGrouped = areObjectsGrouped(object, manipulationObjects[i]);
                
                //if they're not grouped..group them.
                if(areGrouped == -1) {
                    var overlappedObjs = new Array();
                    overlappedObjs[0] = object;
                    overlappedObjs[1] = manipulationObjects[i];
                    groupings[groupings.length] = overlappedObjs;
                }
            }
        }
    }
}*/


/*
 * Function finds whether objects overlaps with any other manipulation object.
 */
function checkObjectOverlap(object) {
    //Check to see if object with object is overlapping any other object that it can be grouped with.
    var manipulationObjects = document.getElementsByClassName('manipulationObject');
    var overlapArray = new Array();
    
    for(var i = 0; i < manipulationObjects.length; i++) { //go through all manipulationObjects, checking for overlap.
        if(object.id != manipulationObjects[i].id) { //Don't check the object you're moving against itself.
            //check to see if objects overlap. If they do, add the object to the array.
            if((object.offsetLeft + object.offsetWidth > manipulationObjects[i].offsetLeft) && (object.offsetLeft < manipulationObjects[i].offsetLeft + manipulationObjects[i].offsetWidth) && (object.offsetTop + object.offsetHeight > manipulationObjects[i].offsetTop) && (object.offsetTop < manipulationObjects[i].offsetTop + manipulationObjects[i].offsetHeight)) {
                
                //check to see if the 2 are already grouped together
                var areGrouped = areObjectsGrouped(object, manipulationObjects[i]);
                
                //This check may need to be moved over to the checkObjectOverlap function.
                //if they're not grouped, group them.
                if(areGrouped == -1) {
                    var overlappedObjs = new Array();
                    overlappedObjs[0] = object;
                    overlappedObjs[1] = manipulationObjects[i];
                    overlapArray[overlapArray.length] = overlappedObjs;
                }
            }
        }
    }
    
    return overlapArray;
}

/* 
 * Function calls checkObjectOverlap to get the array of overlapping objects. 
 * It then takes this array and concatinates it into a string that can be used by the 
 * objectiveC code. 
 */
function checkObjectOverlapString(object) {
    var overlapArray = checkObjectOverlap(object);
    
    if(overlapArray.length > 0) {
        var overlapString = "";
        
        for(var i = 0; i < overlapArray.length - 1; i ++) {
            //overlapString = overlapString + overlapArray[i][0].id + ", " + overlapArray[i][1].id + "; ";
            overlapString = overlapString + overlapArray[i][1].id + ", " ;
        }
        
        //overlapString = overlapString + overlapArray[overlapArray.length - 1][0].id + ", " + overlapArray[overlapArray.length - 1][1].id;
        overlapString = overlapString + overlapArray[overlapArray.length - 1][1].id;
        
        return overlapString;
    }
    else
        return null;
}

/*
 * Function calls checkObjectOverlap to see if this object is overlapping
 * with any other objects. 
 * If it is, then it adds the overlapping objects to the groupings array.
 */
function groupOverlappingObjects(object) {
    var overlapArray = checkObjectOverlap(object);
    
    //Go through the array returned by the checkObjectOverlap function to see if the objects are already grouped. If they aren't, group them.
    for(i = 0; i < overlapArray.length; i ++) {
        groupings[groupings.length] = overlapArray[i];
    }
    
    //Clear all the highlighting because we've finished our grouping.
    //clearAllHighlighted();
}

/*
 * If we want to do this correctly, we'll need to use another function to change the size of the object that fits within
 * the other object. Additionally, we'll have to change the location of the objects when they interact to show that they're
 * interacting.
 * The function takes in two object id parameters. object1 is the object that is being manipulated. Object 2 is the static
 * object that object1 is being grouped with. (x2, y2) correspond to the coordinates of the hotspot for object 2 that
 * the coordinates (x1, y1) of object1 should move toward and snap to.
 */
function groupObjectsAtLoc(object1, x1, y1, object2, x2, y2) {
    var group = new Array();
    group[0] = object1;
    group[1] = object2;

    groupings[groupings.length] = group;
}

/*
 * Get the object ids that are grouped together to display to the user.
 * Return these object ids in a 2D array (of n x 2), where each row represents a link between two objects and is separated
 * by a semicolon. Each element in the row is separated by a comma.
 */
function getGroupedObjectsString(object) {
    //Get objects this object may be grouped with.
    var groupedWithObjects = new Array();
    
    getGroupedObjectsArray(object, groupedWithObjects);

    if(groupedWithObjects.length > 0) {
        var objGroupString = groupedWithObjects[0][0].id + ", " + groupedWithObjects[0][1].id;
    
        for(var i = 1; i < groupedWithObjects.length; i ++) {
            objGroupString = objGroupString + "; " + groupedWithObjects[i][0].id + ", " + groupedWithObjects[i][1].id;
        }
    
        return objGroupString;
    }
    else
        return null;
}

/*
 * Recursive function which finds all objects which are grouped together.
 * Need to recursively check objects due to the fact that 3 or more objects may be grouped at different times.
 * In this case groupedObjects will be an array of pairs of objects that are grouped together. 
 * TODO: come back to this and see if this and getObjectsGroupedWithObject can be combined.
 */
function getGroupedObjectsArray(object, groupedObjects) {
    //Go through the entire 2D array.
    for(var i = 0; i < groupings.length; i++) {
        if(object.id == groupings[i][0].id) {
            if(!pairInList(groupings[i][0], groupings[i][1], groupedObjects)) {
                //alert("found object: " + object.id + " and it's grouped with: " + groupings[i][1].id);
                
                groupedObjects[groupedObjects.length] = groupings[i];
                getGroupedObjectsArray(groupings[i][1], groupedObjects);
            }
        }
        else if(object.id == groupings[i][1].id) {
            if(!pairInList(groupings[i][0], groupings[i][1], groupedObjects)) {
                //alert("found object: " + object.id + " and it's grouped with: " + groupings[i][0].id);
                
                groupedObjects[groupedObjects.length] = groupings[i];
                getGroupedObjectsArray(groupings[i][0], groupedObjects);
            }
        }
    }
}

/* 
 * Recursive function which finds all objects which are grouped together.
 * Need to recursively check objects due to the fact that 3 or more objects may be grouped at different times.
 * Return the list of objects that are all grouped together. 
 */
function getObjectsGroupedWithObject(object, groupedObjects) {
    //Go through the entire 2D array.
    for(var i = 0; i < groupings.length; i++) {
        if(object.id == groupings[i][0].id) {
            if(!objectInList(groupings[i][1], groupedObjects)) {
                groupedObjects[groupedObjects.length] = groupings[i][1];
                getObjectsGroupedWithObject(groupings[i][1], groupedObjects);
            }
        }
        else if(object.id == groupings[i][1].id) {
            if(!objectInList(groupings[i][0], groupedObjects)) {
                groupedObjects[groupedObjects.length] = groupings[i][0];
                getObjectsGroupedWithObject(groupings[i][0], groupedObjects);
            }
        }
    }
}

/* 
 * Used as a helper method for getObjectsGroupedWithObject.
 * Checks to see if the objects is in the list so it isn't added again.
 */
function objectInList(object, objectList) {
    for(var i = 0; i < objectList.length; i ++)
        if(object.id == objectList[i].id)
            return true;
    
    return false;
}

/*
 * Used as a helper method for getGroupedObjectsArray.
 * Checks to see if the pair of objects are in the list so it isn't added again.
 * TODO: come back to this and see if this and objectInList can be combined.
 */
function pairInList(object1, object2, objectList) {
    for(var i = 0; i < objectList.length; i ++) {
        if((object1.id == objectList[i][0].id) && (object2.id == objectList[i][1].id)) {
            //alert("in if, object1 id: " + object1.id + " object2 id: " + object2.id)
            return true;
        }
        else if((object1.id == objectList[i][1]) && (object2.id == objectList[i][0].id)) {
            //alert("in else if, object1 id: " + object1.id + " object2 id: " + object2.id)
            return true;
        }
    }
    
    return false;    
}

/*
 * Returns the index at which the objects are in the array if object1 and object 2 are grouped together, and -1 otherwise.
 */
function areObjectsGrouped(object1, object2) {
    for(var i = 0; i < groupings.length; i ++) {
        if((object1.id == groupings[i][0].id) && (object2.id == groupings[i][1].id))
            return i;
        else if((object2.id == groupings[i][0].id) && (object1.id == groupings[i][1].id))
            return i;
    }
    
    return -1;
}

/* 
 * Ungroups 2 objects from each other.
 */
function ungroupObjects(object1, object2) {
    //alert("ungrouping objects");
    //Get the index at which the objects are grouped.
    var areGrouped = areObjectsGrouped(object1, object2);
        
    //Make sure they are grouped, and if they are, ungroup them.
    if(areGrouped > -1) {
        //alert("ungrouping " + object1.id + " and " + object2.id);
        //alert("groupings length before ungrouping: " + groupings.length);
        groupings.splice(areGrouped, 1);
        //alert("groupings length after ungrouping: " + groupings.length);
    }
}

/*
 * This may be moved into a different js file, if there are more things to do when moving to the next sentence.
 * This function just sets the sentence opacity to the specified opacity.
 * It's used to setup the opacity when the activity loads, and when moving from one sentence to the next. 
 */
function setSentenceOpacity(sentenceId, opacity) {
    sentenceId.style.opacity = opacity;
}

function setSentenceColor(sentenceId, color) {
    sentenceId.style.color = color;
}

function setSentenceFontWeight(sentenceId, weight) {
    sentenceId.style.fontWeight = weight;
}

function highlight(object) {
    object.style.backgroundColor = "rgba(255, 250, 205, .4)";
    //object.style.border = "3px solid rgba(250, 250, 210, .2)";
    
    //When we highlight we also want to draw the hotspots for this object.
    //Not sure if we should call this from here or from the objectiveC code. 
    //drawHotspots(object);
}

function removeHighlight(object) {
    //object.style.border = "0px";
    object.style.backgroundColor = "transparent";
}

function clearAllHighlighted() {
    var manipulationObjects = document.getElementsByClassName('manipulationObject');

    for(var i = 0; i < manipulationObjects.length; i++)
        removeHighlight(manipulationObjects[i]);
}

function drawHotspot(x, y, color) {
    //Create jsColor object
    var col = new jsColor(color);
    
    //Create jsPoint object
    var pt1 = new jsPoint(x,y);
    
    //Draw filled circle with pt1 as center point and radius 30.
    overlayGraphics.fillCircle(col,pt1,10);
}

/*function drawHotspot(x, y, color) {
    var canvas = document.getElementById('overlay');

    //Instead of having to do this, figure out how to properly make it the right size in the epub or through css. 
    //canvas.width = window.innerWidth;
    //canvas.height = window.innerHeight;
    
    //if(canvas == null)
    //    alert("canvas is null");
    //else
    //    alert("size of canvas: " + canvas.width + " x " + canvas.height);
    
    var context = canvas.getContext('2d');
    var radius = 10;

    context.beginPath();
    context.arc(x, y, radius, 0, 2 * Math.PI, false);
    context.fillStyle = color;
    context.fill();
}*/

function clearCanvas() {
    overlayGraphics.clear();
}

/*function clearCanvas() {
    var canvas = document.getElementById('overlay');
    var context = canvas.getContext('2d');

    context.clearRect(0, 0, canvas.width, canvas.height);
}*/