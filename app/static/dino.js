
(() => {
    const canvas = document.getElementById("dino-canvas");
    if (!canvas) return;

    const ctx = canvas.getContext("2d");

    const scoreElement = document.getElementById("dino-score");
    const bestElement = document.getElementById("dino-best");
    const gameOverElement = document.getElementById("dino-game-over");
    const finalScoreElement = document.getElementById("dino-final-score");
    const restartButton = document.getElementById("dino-restart");
    const jumpButton = document.getElementById("dino-jump");

    const WIDTH = canvas.width;
    const HEIGHT = canvas.height;
    const GROUND = 190;

    let dinosaur;
    let obstacles;
    let score;
    let best = Number(localStorage.getItem("dinoBest") || 0);
    let speed;
    let gameRunning;
    let gameOver;
    let lastTime;
    let spawnTimer;
    let animationId;

    bestElement.textContent = best;

    function resetGame() {
        cancelAnimationFrame(animationId);

        dinosaur = {
            x: 85,
            y: GROUND - 48,
            width: 42,
            height: 48,
            velocityY: 0,
            jumping: false
        };

        obstacles = [];
        score = 0;
        speed = 6;
        spawnTimer = 0;
        gameRunning = true;
        gameOver = false;
        lastTime = 0;

        scoreElement.textContent = "0";
        gameOverElement.hidden = true;

        animationId = requestAnimationFrame(gameLoop);
    }

    function jump() {
        if (gameOver) return;

        if (!gameRunning) {
            resetGame();
            return;
        }

        if (!dinosaur.jumping) {
            dinosaur.velocityY = -13;
            dinosaur.jumping = true;
        }
    }

    function createObstacle() {
        const height = 30 + Math.random() * 25;

        obstacles.push({
            x: WIDTH + 20,
            y: GROUND - height,
            width: 20 + Math.random() * 10,
            height: height
        });
    }

    function update(delta) {
        const step = delta / 16.67;

        // Физика прыжка
        dinosaur.velocityY += 0.65 * step;
        dinosaur.y += dinosaur.velocityY * step;

        if (dinosaur.y >= GROUND - dinosaur.height) {
            dinosaur.y = GROUND - dinosaur.height;
            dinosaur.velocityY = 0;
            dinosaur.jumping = false;
        }

        // Создание кактусов
        spawnTimer += delta;

        if (spawnTimer > Math.max(650, 1400 - speed * 45)) {
            createObstacle();
            spawnTimer = 0;
        }

        // Движение препятствий
        obstacles.forEach(obstacle => {
            obstacle.x -= speed * step;
        });

        obstacles = obstacles.filter(obstacle =>
            obstacle.x + obstacle.width > 0
        );

        // Увеличение скорости
        speed += 0.0015 * step;

        // Счёт
        score += delta * 0.01;
        scoreElement.textContent = Math.floor(score);

        // Проверка столкновений
        for (const obstacle of obstacles) {
            const hit =
                dinosaur.x + dinosaur.width - 8 > obstacle.x + 3 &&
                dinosaur.x + 8 < obstacle.x + obstacle.width - 3 &&
                dinosaur.y + dinosaur.height - 5 > obstacle.y + 3 &&
                dinosaur.y + 5 < obstacle.y + obstacle.height;

            if (hit) {
                endGame();
                return;
            }
        }
    }

    function draw() {
        ctx.clearRect(0, 0, WIDTH, HEIGHT);

        // Небо
        ctx.fillStyle = "#f5f8ef";
        ctx.fillRect(0, 0, WIDTH, HEIGHT);

        // Облака
        ctx.fillStyle = "#dce8d3";
        ctx.font = "25px Arial";
        ctx.fillText("☁", 180, 55);
        ctx.fillText("☁", 520, 80);
        ctx.fillText("☁", 760, 45);

        // Земля
        ctx.strokeStyle = "#718c61";
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(0, GROUND);
        ctx.lineTo(WIDTH, GROUND);
        ctx.stroke();

        // Точки на земле
        ctx.fillStyle = "#a6b997";
        for (let i = 0; i < WIDTH; i += 35) {
            ctx.fillRect(i, GROUND + 12, 3, 2);
        }

        // Динозаврик
        const x = dinosaur.x;
        const y = dinosaur.y;

        ctx.fillStyle = "#478c45";

        // Тело
        ctx.fillRect(x + 5, y + 13, 29, 25);

        // Голова
        ctx.fillRect(x + 23, y, 20, 23);

        // Хвост
        ctx.beginPath();
        ctx.moveTo(x + 7, y + 20);
        ctx.lineTo(x - 7, y + 29);
        ctx.lineTo(x + 7, y + 31);
        ctx.fill();

        // Глаз
        ctx.fillStyle = "#ffffff";
        ctx.fillRect(x + 34, y + 6, 5, 5);

        ctx.fillStyle = "#222222";
        ctx.fillRect(x + 36, y + 7, 2, 3);

        // Ноги
        ctx.fillStyle = "#356f35";

        if (dinosaur.jumping) {
            ctx.fillRect(x + 9, y + 35, 7, 10);
            ctx.fillRect(x + 26, y + 35, 7, 10);
        } else {
            const legFrame = Math.floor(Date.now() / 100) % 2;
            ctx.fillRect(x + 9, y + 35, 7, legFrame ? 12 : 7);
            ctx.fillRect(x + 26, y + 35, 7, legFrame ? 7 : 12);
        }

        // Кактусы
        obstacles.forEach(obstacle => {
            ctx.fillStyle = "#328c43";

            ctx.fillRect(
                obstacle.x,
                obstacle.y,
                obstacle.width,
                obstacle.height
            );

            ctx.fillRect(
                obstacle.x - 7,
                obstacle.y + 12,
                8,
                7
            );

            ctx.fillRect(
                obstacle.x - 7,
                obstacle.y + 5,
                5,
                14
            );

            ctx.fillRect(
                obstacle.x + obstacle.width - 1,
                obstacle.y + 20,
                8,
                7
            );
        });
    }

    function endGame() {
        gameRunning = false;
        gameOver = true;

        const finalScore = Math.floor(score);

        if (finalScore > best) {
            best = finalScore;
            localStorage.setItem("dinoBest", best);
            bestElement.textContent = best;
        }

        finalScoreElement.textContent = finalScore;
        gameOverElement.hidden = false;
    }

    function gameLoop(timestamp) {
        if (!gameRunning) return;

        const delta = lastTime ? Math.min(timestamp - lastTime, 40) : 16.67;
        lastTime = timestamp;

        update(delta);
        draw();

        if (gameRunning) {
            animationId = requestAnimationFrame(gameLoop);
        }
    }

    // Управление клавиатурой
    document.addEventListener("keydown", event => {
        if (event.code === "Space" || event.code === "ArrowUp") {
            event.preventDefault();

            if (!event.repeat) jump();
        }
    });

    // Управление кнопкой
    jumpButton.addEventListener("click", jump);

    // Прыжок нажатием на игровое поле
    canvas.addEventListener("pointerdown", jump);

    // Перезапуск
    restartButton.addEventListener("click", resetGame);

    resetGame();
})();
