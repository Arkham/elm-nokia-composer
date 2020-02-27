let app = Elm.Main.init({ node: document.querySelector('main') })

let context;

let play = function(tune, context) {
  let real = new Float32Array([0.26, 0.36, 0.57, 0.84, 1, 0.79, 0.72, 0.76, 0.82, 0.84, 0.64, 0.35, 0.12, 0.19, 0.23, 0.21, 0.08, 0.10, 0.17, 0.27, 0.22, 0.20, 0.22, 0.15, 0.13, 0.12, 0.11, 0.11, 0.10, 0.09, 0.09, 0.08, 0.08, 0.07, 0.08, 0.06, 0.04, 0.03, 0.02, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0, 0]);
  let imag = new Float32Array(64);
  imag.fill(0);
  let wave = context.createPeriodicWave(real, imag);

  return tune.reduce(function(acc, elem) {
    let oscillator = context.createOscillator();
    oscillator.setPeriodicWave(wave);
    oscillator.frequency.value = elem.frequency;

    let gainNode = context.createGain();
    gainNode.gain.value = 0;

    oscillator.connect(gainNode);
    gainNode.connect(context.destination);

    let startMoment = context.currentTime + acc.now;
    let endMoment = startMoment + elem.duration;

    if (elem.frequency !== 0) {
      gainNode.gain.setTargetAtTime(1.0, startMoment, 0.002);
      gainNode.gain.setTargetAtTime(0, endMoment - 0.002, 0.002);
    }

    oscillator.start(startMoment);
    oscillator.stop(endMoment);

    return({
      now: acc.now + elem.duration,
      lastOscillator: oscillator
    });
  }, {
    now: 0,
    lastOscillator: null
  });
};

let playLoop = function(tune, context) {
  let result = play(tune, context);
  result.lastOscillator.onended = function() {
    playLoop(tune, context);
  };
};

app.ports.play.subscribe(function(data) {
  console.log(data);
  context = new AudioContext();

  if (data.looping) {
    playLoop(data.ringtone, context);
  } else {
    let result = play(data.ringtone, context);

    result.lastOscillator.onended = function() {
      app.ports.finished.send("done");
    }
  }
});

app.ports.stop.subscribe(function() {
  if (context) {
    context.close();
    context = null;
  }
});
