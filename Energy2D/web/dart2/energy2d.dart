library Energy2D;

import 'dart:html';
import 'dart:math';
import 'dart:async';

part 'fluidsolver.dart';
part 'heatsolver.dart';
part 'mathutil.dart';
part 'matrix.dart';
part 'model.dart';
part 'thermalboundary.dart';
part 'massboundary.dart';
part 'part.dart';

const double AIR_THERMAL_CONDUCTIVITY = 0.025;
const int AIR_SPECIFIC_HEAT = 1012;
const double AIR_DENSITY = 1.204;

/*
 * By default, air's kinematic viscosity = 1.568 x 10^-5 m^2/s at 27 C is
 * used. It can be set to zero for inviscid fluid.
 */
const double AIR_VISCOSITY = 0.00001568;

CanvasRenderingContext2D ctx;

Model2D model;

int width = 100;
int height = 100;
bool running = false;
Timer timer = null;

void main() {

  model = new Model2D(100, 100);

  CanvasElement canvas = querySelector("#world");
  width = canvas.width;
  height = canvas.height;
  ctx = canvas.getContext('2d');

  canvas.onClick.listen(startStop);
}


void startStop(MouseEvent event) {
  if (running) {
    if (timer != null) {
      timer.cancel();
    }
  } else {
    timer = new Timer.periodic(const Duration(milliseconds: 30), step);
    print("starting");
  }
  running = !running;
}


void draw() {
  Matrix<double> t = model.t;

  double cw = width / model.nx;
  double ch = height / model.ny;

  // min -30 C
  // max 50 C

  double minT = 0.0;
  double maxT = 50.0;

  for (int i=0; i<t.cols; i++) {
    for (int j=0; j<t.rows; j++) {
      double temp = t[i][j];
      int r = max(min(255, (((temp - minT) / (maxT - minT)) * 255).round()),0.0);
      ctx.fillStyle = 'rgb($r, 10, 10)';
      ctx.fillRect(i * cw, j * ch, cw, ch);
    }
  }
  print('Temperature is ${t[45][45]}');
}


void step(Timer timer) {
  for (int i=0; i<100; i++) {
    model.nextStep();
  }
  draw();
}
