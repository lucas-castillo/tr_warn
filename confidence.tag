<confidence>
    <style>
        div#instructions{
            font-size: 22px;
            padding: 20px;
        }
        .psychErrorMessage{ /*override style*/
            font-size: 23px;
            text-align: center;
        }
        label {
            font-size: 20px;
            padding-bottom: 5px;
            margin: 5px;
        }

        .slider {
            -webkit-appearance: none;
            width: 100%;
            height: 15px;
            border-radius: 5px;
            background: linear-gradient(to right, #82CFD0 0%, #82CFD0 50%, #fff 50%, #fff 100%);
            outline: none;
            opacity: 0.7;
            -webkit-transition: .2s;
            transition: opacity .2s;
        }

        .slider::-webkit-slider-thumb {
            -webkit-appearance: none;
            appearance: none;
            width: 25px;
            height: 25px;
            border-radius: 50%;
            background: black;
            cursor: pointer;
        }

        .slider::-moz-range-thumb {
            width: 25px;
            height: 25px;
            border-radius: 50%;
            background: black;
            cursor: pointer;
        }

    </style>
    <div id = "instructions">
        In the next screen you will watch <b>the same animation again</b>. Remember that it starts like this:
    </div>
    <br>

    <div>
        <canvas width="950" height="400" style="border: solid black 2px" ref="myCanvas"></canvas>
        <p style="font-size: 20px">{confidenceQuestion}</p>
        <div style="width: 950px">
            <label for="slider">Not Confident</label>
            <label for="slider" style="float: right">Very Confident</label>
        </div>
        <div class="slidercontainer" id="sliderCont">
            <input id = "slider" onmouseup="{sliderMouseUp}" oninput="{sliderChange}" type="range" min="0" max="200" value="100" class="slider" style="width:950px; z-index: 0" refs="confidenceSlider">
            <span class="dot" ref="myPrompt"></span>
        </div>
        <br>
        <p class="psychErrorMessage" show="{hasErrors}" >{errorText}</p>
    </div>
    <script>
        var self = this;
        function shuffleArray(array){
            for (let i = array.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [array[i], array[j]] = [array[j], array[i]];
            }
        }
        self.sliderTouches = 0;
        self.hasErrors = false;

        self.confidenceQuestion = ""

        // test vars that can be changed
        self.colours = ["red", "blue", "purple"];
        self.squareDimensions = [50, 50];
        self.speed = 0.3;
        self.showFlash = true;
        self.answers = ["Red will move, then Blue will move, then Purple will move", "Red will move, then Purple will move, then Blue will move", "Red will move, then Blue and Purple will move at the same time"];
        self.questions = self.answers.slice();
        shuffleArray(self.questions);

        // define what a moving display is - common to all .tags (see inner starting comments for minor changes according to tag needs)
        self.MovingDisplay = function (colours, mirroring, launchTiming, extraObjs, squareDimensions, canvas, slider = null, speed, showFlash = false) {
            // What's different about this Moving Display?
            // no hole in blue square!
            var display = this;

            // def functions

            display.Square = function (colour, dimensions) {
                var sq = this;
                // colour
                sq.colourName = colour;
                switch (sq.colourName) {
                    case "red":
                        sq.colour = "#FF0000";
                        break;
                    case "green":
                        sq.colour = "#00FF00";
                        break;
                    case "blue":
                        sq.colour = "#0000FF";
                        break;
                    case "black":
                        sq.colour = "#000000";
                        break;
                    case "hidden":
                        sq.colour = "#FFFFFF";
                        break;
                    case "purple":
                        sq.colour = "#ec00f0";
                        break;
                }
                // geometry
                sq.dimensions = dimensions;
                sq.startPosition = [0, 0];
                sq.finalPosition = [0, 0];
                sq.moveAt = 0;
                sq.movedAt = -1; // the time it actually moved
                sq.position = [0, 0];
                sq.duration = 0;

                sq.animationTimer = 0;
                sq.pixelsPerStep = [0, 0];



                sq.draw = function (canvas, step) {
                    var myStep = Math.max(0, step - sq.moveAt);

                    if (myStep < sq.duration) {
                        sq.position[0] = sq.startPosition[0] + sq.pixelsPerStep[0] * myStep;
                        sq.position[1] = sq.startPosition[1] + sq.pixelsPerStep[1] * myStep;
                    } else {
                        sq.position[0] = sq.finalPosition[0];
                        sq.position[1] = sq.finalPosition[1];
                    }

                    sq.obedientDraw(canvas);


                    if (sq.movedAt === -1 && myStep > 0) {
                        sq.movedAt = step;
                    }
                };

                sq.obedientDraw = function (canvas) {
                    // draws sq in its position, without asking questions! useful sometimes
                    var ctx = canvas.getContext("2d");
                    ctx.fillStyle = sq.colour;
                    ctx.fillRect(sq.position[0], sq.position[1], sq.dimensions[0], sq.dimensions[1]);
                };


                sq.reset = function () {
                    sq.movedAt = -1;
                    sq.position = sq.startPosition.slice();
                    sq.pixelsPerStep = [(sq.finalPosition[0] - sq.startPosition[0]) / sq.duration,
                        (sq.finalPosition[1] - sq.startPosition[1]) / sq.duration];
                };

            };

            display.placeSquares = function () {
                for (var i = 0; i < 3; i++) {
                    var newSquare, squareColour;
                    squareColour = display.colours[i];
                    newSquare = new display.Square(squareColour, display.squareDimensions);
                    display.squareList.push(newSquare);
                }
                display.setUp();
            };
            display.setUp = function () {
                var canvasMargin = display.canvas.width / 4;

                for (var i = 0; i < 3; i++) {
                    // start/end positions
                    var square = display.squareList[i];
                    var sqWidth = display.squareDimensions[0];
                    var startPosition, endPosition;
                    if (i === 0) {
                        startPosition = display.mirrored ? canvasMargin + 5 * sqWidth : canvasMargin;
                        endPosition = display.mirrored ? startPosition - 2.5 * sqWidth : canvasMargin + 2.5 *
                            sqWidth;
                    } else {
                        var distanceTravelled = sqWidth + 2 * sqWidth * (i - 1);
                        startPosition = display.mirrored ?
                            display.squareList[0].finalPosition[0] - distanceTravelled: // if mirrored travel left from A
                            display.squareList[0].finalPosition[0] + distanceTravelled; // if not travel right
                        endPosition = display.mirrored ?
                            startPosition - sqWidth : // same idea
                            startPosition + sqWidth;
                    }
                    square.startPosition = [startPosition, 100];
                    square.finalPosition = [endPosition, 100];

                    // duration
                    square.duration = Math.abs(endPosition - startPosition) / display.speed;
                    display.durations.push(square.duration);
                }
                display.draw();

                // give "move At" instructions
                if (display.launchTiming === "canonical") {
                    display.squareList[0].moveAt = 0;
                    display.squareList[1].moveAt = display.squareList[0].duration;
                    display.squareList[2].moveAt = display.squareList[1].moveAt + display.squareList[1].duration;
                } else {
                    display.squareList[0].moveAt = 0;
                    display.squareList[2].moveAt = display.squareList[0].duration;
                    display.squareList[1].moveAt = display.squareList[2].moveAt + display.squareList[2].duration;
                }
            };
            display.reset = function () {
                // reset squares to startPosition
                for (var i = 0; i < 3; i++) {
                    display.squareList[i].reset();
                }
                // reset other animation markers
                display.flashOnset = -1;
                display.animationStarted = Infinity;
                display.animationEnded = false;
            };


            display.startAnimation = function () {
                display.animationStarted = Date.now();
                window.requestAnimationFrame(display.draw.bind(display));
            };
            display.endAnimation = function () {
                display.animationEnded = Date.now();
            };

            display.animate = function (startAt = 1000) {
                // stop timeouts
                for (var i = 0; i < display.animationTimer.length; i++) {
                    clearTimeout(display.animationTimer[i])
                }
                //
                // these two put everything back to start
                display.reset();
                display.draw();
                // and this starts the timing
                display.setTimeouts(startAt);
            };

            display.getLastFinish = function () {
                // get list of when each sq finishes moving
                var finishTimings = [];
                for (var i = 0; i < 3; i++) {
                    if (display.squareList[i].colourName !== "hidden") {
                        finishTimings.push((display.squareList[i].moveAt + display.squareList[i].duration));
                    }
                };
                // and what time is last
                return Math.max.apply(null, finishTimings);
            };

            display.setTimeouts = function (startInstructions = 1000) {
                // get list of when each sq finishes moving
                var finishTimings = display.squareList.map(function (obj) {
                    return obj.moveAt + obj.duration
                });
                var lastFinish = Math.max.apply(null, finishTimings); // and what time is last
                var startAt = startInstructions; // some external callings may want no delay when starting (e.g. check training tags). 1000ms lets page load up
                var timeoutId;  //  start timeouts for start and end and add to a list (which allows to stop everything if animation restarted, see self.animate())
                timeoutId = setTimeout(display.startAnimation.bind(display), startAt);
                display.animationTimer.push(timeoutId);
                timeoutId = setTimeout(display.endAnimation.bind(display), startAt + lastFinish);
                display.animationTimer.push(timeoutId);
                // timings for flash
                if (display.showFlash) {
                    var animationSpace = lastFinish + 1000; // add 1000s so one can set flash after lastFinish
                    var flashTime =  startAt - 750 + animationSpace / 200 * display.slider.value; // if slider.value == 0 flash 750ms before red starts moving (250ms after animation start).
                    // 0 ----------------------- 250 --------------------- 1000 ---------------------------- lastFinish ---------------- lastFinish + 1000 -----> // time arrow (ms)
                    //(animationStart) --- (earliestPossibleFlash) ------(startAt: red starts moving) -----(lastSquare stops moving) --(last possible Flash) --->

                    timeoutId = setTimeout(display.displayFlash.bind(display), flashTime);
                    display.animationTimer.push(timeoutId);
                    timeoutId = setTimeout(display.displayFlash.bind(display), flashTime + 25); // this makes the flash 25ms long
                    display.animationTimer.push(timeoutId);
                }
            };
            display.draw = function () {
                // empty canvas
                var ctx = display.canvas.getContext("2d");
                ctx.clearRect(0, 0, display.canvas.width, display.canvas.height);
                // draw squares
                var step = Date.now() - display.animationStarted;
                for (var i = 0; i < display.squareList.length; i++) {
                    display.squareList[i].draw(display.canvas, step);
                }

                // // draw the hole for middle third of the B square
                // if (display.squareList[1].colourName !== "hidden") {
                //     ctx.fillStyle = display.holeColour;
                //     ctx.fillRect(
                //         display.squareList[1].position[0],
                //         display.squareList[1].position[1] + 1 / 3 * display.squareList[1].dimensions[1],
                //         display.squareList[1].dimensions[0],
                //         1 / 3 * display.squareList[1].dimensions[1]
                //     );
                // }

                if (display.extraObjs) {
                    display.drawExtraObjects()
                }
                if (!display.animationEnded) {
                    window.requestAnimationFrame(display.draw.bind(display));
                }
            };
            display.drawExtraObjects = function () {
                var ctx = display.canvas.getContext('2d');
                // some vars to make more legible
                var squareA = display.squareList[0];
                var squareB = display.squareList[1];
                var squareC = display.squareList[2];

                // stick
                if (display.squareList[0].colourName !== "hidden") {
                    var stickSize = squareA.dimensions[0] * 2.5;

                    var startX, endX;
                    if (display.mirrored) {
                        startX = squareA.position[0];
                        endX = startX - stickSize;
                    } else {
                        startX = squareA.position[0] + squareA.dimensions[0];
                        endX = startX + stickSize;
                    }

                    // horizontal line
                    ctx.beginPath();
                    ctx.moveTo(startX, squareA.position[1] + 0.5 * squareA.dimensions[1]);
                    ctx.lineTo(endX,squareA.position[1] + 0.5 * squareA.dimensions[1]);
                    ctx.stroke();
                    // vertical line
                    ctx.beginPath();
                    ctx.moveTo(endX, squareA.position[1] + 0.5 * squareA.dimensions[1] - 5);
                    ctx.lineTo(endX, squareA.position[1] + 0.5 * squareA.dimensions[1] + 5);
                    ctx.stroke();
                }

                // draw chain
                if (display.squareList[1].colourName !== "hidden" && display.squareList[2].colourName !== "hidden") {
                    var squareBMiddleX, squareBY, squareCMiddleX, squareCY;
                    squareBMiddleX = squareB.position[0] + squareB.dimensions[0] * 1 / 2;
                    squareCMiddleX = squareC.position[0] + squareC.dimensions[0] * 1 / 2;
                    squareBY = squareB.position[1] + squareB.dimensions[1] * 9 / 10;
                    squareCY = squareC.position[1] + squareC.dimensions[1] * 9 / 10;

                    var distanceBetweenSquares, squareMiddlePoint;
                    distanceBetweenSquares = Math.abs(squareBMiddleX - squareCMiddleX);
                    squareMiddlePoint = display.mirrored ?
                        distanceBetweenSquares / 2 + squareCMiddleX :
                        distanceBetweenSquares / 2 + squareBMiddleX;

                    var controlPointY = squareB.position[1] + squareB.dimensions[1] + 120 - 0.75 * distanceBetweenSquares;

                    // chain is Q bezier curve defined by points (squareBMiddleX, squareBY), (squareMiddlePoint, controlPointY) and (squareCMiddleX, squareBY)
                    ctx.beginPath();
                    ctx.moveTo(squareBMiddleX, squareBY);
                    ctx.quadraticCurveTo(squareMiddlePoint, controlPointY, squareCMiddleX, squareCY);
                    ctx.stroke();
                }

                // wall
                if (display.drawWall) {
                    var wallX;
                    var wallY = display.squareList[2].startPosition[1] - display.squareDimensions[1];
                    var wallWidth = 1 * display.squareDimensions[1];
                    var wallHeight = 3 * display.squareDimensions[1];
                    if (self.mirroring) {
                        wallX = display.squareList[2].startPosition[0] + display.squareDimensions[0] - wallWidth - 1;
                    } else {
                        wallX = display.squareList[2].startPosition[0] + 1;
                    }

                    // ctx.beginPath();
                    // ctx.rect(wallX, wallY, wallWidth, wallHeight);
                    // ctx.stroke();
                    ctx.fillStyle = "#c87630";
                    ctx.fillRect(wallX, wallY, wallWidth, wallHeight);
                    // bricks
                    var brickWidth = wallWidth / 3;
                    var brickHeight = wallHeight / 10;
                    for (var r = 0; r < 10; r++) {
                        if (r !== 0) {
                            // hor lines
                            ctx.beginPath();
                            ctx.moveTo(wallX, wallY + r * brickHeight);
                            ctx.lineTo(wallX + wallWidth, wallY + r * brickHeight);
                            ctx.stroke();
                        }
                        if (r % 2 === 0) {
                            for (var c = 0; c < 3; c++) {
                                if (c !== 0) {
                                    ctx.beginPath();
                                    ctx.moveTo(wallX + c * brickWidth, wallY + r * brickHeight);
                                    ctx.lineTo(wallX + c * brickWidth, wallY + (r + 1) * brickHeight);
                                    ctx.stroke();
                                }
                            }
                        } else {
                            for (var c = 0; c < 3; c++) {
                                ctx.beginPath();
                                ctx.moveTo(wallX + (c + .5) * brickWidth, wallY + r * brickHeight);
                                ctx.lineTo(wallX + (c + .5) * brickWidth, wallY + (r + 1) * brickHeight);
                                ctx.stroke();
                            }
                        }
                    }
                }
            };
            display.displayFlash = function () {
                if (display.showFlash === true) {
                    if (display.flashState === false) {
                        display.flashOnset = Date.now();
                        display.canvas.style.backgroundColor = "black";
                        display.flashState = true;

                        // make squares black if they are hidden
                        for (var i = 0; i < display.squareList.length; i++) {
                            if (display.squareList[i].colourName === "hidden") {
                                display.squareList[i].colour = "#000000";
                                display.squareList[i].obedientDraw(display.canvas);
                            }
                        }
                    } else {
                        display.canvas.style.backgroundColor = "white";
                        display.flashState = false;
                        // make squares white again if they are hidden
                        for (var i = 0; i < display.squareList.length; i++) {
                            if (display.squareList[i].colourName === "hidden") {
                                display.squareList[i].colour = "#FFFFFF";
                                display.squareList[i].obedientDraw(display.canvas);
                            }
                        }
                    }
                    display.draw(); // avoids funky lines if animation has ended
                }
            };


            // initialize attributes
            display.colours = colours; // expressed in ABC order
            display.mirrored = mirroring;
            display.launchTiming = launchTiming;
            display.extraObjs = extraObjs;
            display.squareDimensions = squareDimensions;
            display.canvas = canvas;
            display.slider = slider;
            display.speed = speed;
            display.showFlash = showFlash;

            display.holeColour = "#d9d2a6";
            display.animationStarted = Infinity;
            display.drawWall = false;
            display.animationEnded = true;
            display.flashState = false; // is the canvas flashing at the moment?
            display.animationTimer = []; // holds all the timeout ids so cancelling is easy
            display.durations = [];
            display.squareList = [];
            display.flashOnset = -1; // time when flash starts

            display.placeSquares();
            display.reset();
        };

        // overwrite funcs
        self.onInit = function () {
            // get condition info + mirroring
            self.mirroring = self.experiment.condition.factors.mirroring;
            self.launchTiming = self.experiment.condition.factors.order;
            self.knowledge = self.experiment.condition.factors.knowledge;

            // make rect
            self.rectangle = new self.MovingDisplay(self.colours, self.mirroring, self.launchTiming, extraObjs = false, self.squareDimensions, self.refs.myCanvas, null, self.speed, false);
            //
            document.getElementById("slider").value = Math.floor(Math.random() * 201);
        };

        self.onShown = function (){
            let canonicalOrder = "Red, Blue, Purple";
            let reversedOrder = "Red, Purple, Blue";
            let correctOrder = self.launchTiming === "canonical" ? canonicalOrder : reversedOrder;
            correctOrder = self.knowledge === "informed" ? " (" + correctOrder + ") " : " "
            self.confidenceQuestion = "How certain are you now of your ability to see the correct" + correctOrder + "order of events?";
            self.sliderChange();
        }
        self.canLeave = function () {

            self.hasErrors = false;
            if (self.sliderTouches === 0) {
                self.errorText = "Please click on the slider to indicate how confident you are.";
                self.hasErrors = true;
                return false;
            } else {
                return true;
            }
        };

        self.results = function () {
            let confidenceValue = document.getElementById("slider").value / 2;
            return {"confidence":confidenceValue}

        };

        // own funcs

        self.sliderMouseUp = function () {
            self.sliderTouches++;
        }

        self.sliderChange = function(){
            let confidenceValue = document.getElementById("slider").value / 200;
            let origin = [194, 67, 27]
            let destiny = [71, 184, 61]
            let newcolor = [
                Math.floor((destiny[0] - origin[0]) * confidenceValue + origin[0]),
                Math.floor((destiny[1] - origin[1]) * confidenceValue + origin[1]),
                Math.floor((destiny[2] - origin[2]) * confidenceValue + origin[2])
            ]
            let hashCol = rgbToHex(newcolor[0], newcolor[1], newcolor[2]);
            let value = confidenceValue * 100;
            document.getElementById("slider").style.background = 'linear-gradient(to right, ' + hashCol +' 0%, '+ hashCol + ' ' + value + '%, #fff ' + value + '%, white 100%)'
        }

        function componentToHex(c) {
            var hex = c.toString(16);
            return hex.length == 1 ? "0" + hex : hex;
        }
        function rgbToHex(r, g, b) {
            return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
        }


    </script>
</confidence>