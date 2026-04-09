class DiceRoller {
  constructor(container) {
    this.container = container;
    this.buildDice();
    
    // State
    this.isRolling = false;
    this.currentRotX = 0;
    this.currentRotY = 0;
  }

  buildDice() {
    this.container.innerHTML = '';
    
    const diceDiv = document.createElement('div');
    diceDiv.className = 'd20';
    this.dice = diceDiv;
    
    // Add grid helpers (optional, ignoring for clean look)
    
    // Build 20 sections
    for (let i = 1; i <= 20; i++) {
        let section = document.createElement('section');
        let span = document.createElement('span');
        span.innerText = i.toString();
        
        // Items that are upside down in geometry need text flipped
        if (i % 2 === 0 && i <= 10) span.style.transform = "rotate(180deg)";
        if (i >= 16) span.style.transform = "rotate(180deg)";
        
        section.appendChild(span);
        this.dice.appendChild(section);
    }
    
    this.indicator = document.createElement('div');
    this.indicator.className = 'combat-actor-indicator';
    this.indicator.style.opacity = '0';
    this.container.appendChild(this.indicator);
    
    this.container.appendChild(this.dice);
  }

  getRotationForNumber(num) {
    // Inverse rotations to bring face `num` to front.
    // CSS side-angle = 10.7deg, penta-angle = 52.6deg
    const SA = 10.7;
    const PA = 52.6;
    
    // We add 360 * random(2, 4) to spin it multiple times before landing
    // Actually, just maintain an absolute accumulator to ensure it spins forward
    
    const faceRotations = {
      1:  { x: SA, y: 0 },
      3:  { x: SA, y: 72 },
      5:  { x: SA, y: 144 },
      7:  { x: SA, y: -144 },
      9:  { x: SA, y: -72 },
      
      2:  { x: -SA, y: 0, z: 180 },
      4:  { x: -SA, y: -72, z: 180 },
      6:  { x: -SA, y: -144, z: 180 },
      8:  { x: -SA, y: 144, z: 180 },
      10: { x: -SA, y: 72, z: 180 },
      
      11: { x: -PA, y: -180 },
      12: { x: -PA, y: 108 },
      13: { x: -PA, y: 36 },
      14: { x: -PA, y: -36 },
      15: { x: -PA, y: -108 },
      
      16: { x: -PA, y: 0, z: 180 },
      17: { x: -PA, y: 72, z: 180 },
      18: { x: -PA, y: 144, z: 180 },
      19: { x: -PA, y: -144, z: 180 },
      20: { x: -PA, y: -72, z: 180 }
    };
    
    return faceRotations[num] || faceRotations[20];
  }

  roll(value, actor) {
    if (this.isRolling) return;
    this.isRolling = true;
    
    // Set Indicator text
    if (actor === "hero") {
        this.indicator.innerText = "ХОД ГЕРОЯ";
        this.indicator.style.color = "#d4af37";
        this.indicator.style.borderColor = "#d4af37";
    } else {
        this.indicator.innerText = "ХОД ВРАГА";
        this.indicator.style.color = "#ef4444";
        this.indicator.style.borderColor = "#ef4444";
    }
    this.indicator.style.opacity = '1';
    
    const target = this.getRotationForNumber(value);
    
    // Calculate spins
    // Ensure we always add at least 720 degrees to existing rotation to cause spinning.
    const spins = 2; // full 360 spins
    
    // Math logic: find nearest equivalent angle that satisfies spins.
    // To keep it simple, absolute positioning:
    // currentRotX and currentRotY are stored.
    
    // Just add 1080 deg (3 spins) + new target absolute
    const spinX = 360 * spins;
    const spinY = 360 * spins;
    const spinZ = target.z ? 360 * spins + target.z : 360 * spins;
    
    // Because we just want it to "spin", we reset to 0 in a tick without animation
    this.dice.style.transition = 'none';
    this.dice.style.transform = `rotateX(${this.currentRotX % 360}deg) rotateY(${this.currentRotY % 360}deg)`;
    
    void this.dice.offsetWidth; // Reflow
    
    const nextX = (target.x || 0) + spinX;
    const nextY = (target.y || 0) + spinY;
    const nextZ = (target.z || 0) + (spinZ - 360 * spins);

    this.dice.style.transition = 'transform 1.5s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
    this.dice.style.transform = `rotateZ(${nextZ}deg) rotateX(${nextX}deg) rotateY(${nextY}deg)`;
    
    this.currentRotX = nextX;
    this.currentRotY = nextY;
    
    setTimeout(() => {
        this.isRolling = false;
        setTimeout(() => {
            this.indicator.style.opacity = '0';
        }, 1500);
    }, 1500);
  }
}

export const DiceRollerHook = {
  mounted() {
    this.roller = new DiceRoller(this.el);
    
    this.handleEvent("combat_roll", ({roll, damage, is_hit, actor}) => {
        this.roller.roll(roll, actor);
        
        if (damage > 0) {
            setTimeout(() => {
                const flt = document.createElement('div');
                flt.className = 'absolute font-headline font-bold text-3xl z-50 pointer-events-none drop-shadow-md';
                flt.style.animation = 'floatUpAndFade 2s ease-out forwards';
                
                if (actor === "hero") {
                    flt.classList.add("text-red-500");
                    flt.style.right = '10%';
                    flt.style.bottom = '20%';
                } else {
                    flt.classList.add("text-orange-500");
                    flt.style.left = '10%';
                    flt.style.bottom = '20%';
                }
                
                flt.innerText = `-${damage}`;
                this.el.parentElement.appendChild(flt);
                
                setTimeout(() => flt.remove(), 2000);
            }, 1500); // Wait for dice roll animation
        }
    });

    this.handleEvent("initiative_roll", ({hero_roll, enemy_roll, turn}) => {
        // Just roll one of the dice to show action
        this.roller.roll(hero_roll, "hero");
        this.roller.indicator.innerText = `ИНИЦИАТИВА! Герой: ${hero_roll}`;
    });
  }
};

const style = document.createElement('style');
style.innerHTML = `
@keyframes floatUpAndFade {
  0% { transform: translateY(0) scale(0.5); opacity: 0; }
  20% { transform: translateY(-20px) scale(1.2); opacity: 1; }
  80% { transform: translateY(-60px) scale(1); opacity: 1; }
  100% { transform: translateY(-80px) scale(0.9); opacity: 0; }
}
`;
document.head.appendChild(style);
