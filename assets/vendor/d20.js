class DiceRoller {
  constructor(container) {
    this.container = container;
    this.buildDice();
    
    this.isRolling = false;
  }

  buildDice() {
    this.container.innerHTML = '';
    
    const diceWrapper = document.createElement('div');
    diceWrapper.className = 'dice-spinner-wrapper';
    
    const diceCircle = document.createElement('div');
    diceCircle.className = 'dice-circle';
    
    this.diceNumber = document.createElement('span');
    this.diceNumber.className = 'dice-number';
    this.diceNumber.innerText = '?';
    
    diceCircle.appendChild(this.diceNumber);
    diceWrapper.appendChild(diceCircle);
    
    this.indicator = document.createElement('div');
    this.indicator.className = 'combat-actor-indicator';
    this.indicator.style.opacity = '0';
    diceWrapper.appendChild(this.indicator);
    
    this.container.appendChild(diceWrapper);
    this.diceCircle = diceCircle;
    this.diceWrapper = diceWrapper;
  }

  roll(value, actor) {
    if (this.isRolling) return;
    this.isRolling = true;
    
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
    
    this.diceCircle.classList.remove('rolled');
    this.diceNumber.innerText = '?';
    
    void this.diceCircle.offsetWidth;
    
    this.diceCircle.classList.add('rolling');
    
    setTimeout(() => {
      this.diceCircle.classList.remove('rolling');
      this.diceCircle.classList.add('rolled');
      this.diceNumber.innerText = value.toString();
      this.isRolling = false;
      
      setTimeout(() => {
        this.indicator.style.opacity = '0';
      }, 1500);
    }, 1200);
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
        }, 1200);
      }
    });

    this.handleEvent("initiative_roll", ({hero_roll, enemy_roll, turn}) => {
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