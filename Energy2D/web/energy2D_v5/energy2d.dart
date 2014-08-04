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
FluidSolver2D fluid;


int width = 400;
int height = 400;
bool running = false;
Timer timer = null;

Matrix<double> t;
Matrix<double> q;
int nx;
int ny;
double cw;
double ch;
double t0;

void main() {

  model = new Model2D(50,50);

  t = model.t;
  q = model.q;
  nx = model.nx;
  ny = model.ny;
  cw = width / model.nx;
  ch = height / model.ny;

  CanvasElement canvas = querySelector("#world");
  width = canvas.width;
  height = canvas.height;
  ctx = canvas.getContext('2d');

  canvas.onClick.listen(startStop);
//  thermostat();
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


      int r, h;

      for (int i=0; i<t.cols; i++) {
        for (int j=0; j<t.rows; j++) {
          double temp = t[i][j];

          int h = 0;
         if (!temp.isNaN && !temp.isInfinite) {
            h = (255.8 - (3.75 * temp)).round();
          //  r = max(min(255, (((temp - minT) / (maxT - minT)) * 255).round()),0.0);
         }

          if (model.fluidity[i][j]) {
            ctx.fillStyle = 'hsl($h, 85%, 50%)';
          } else {
            ctx.fillStyle = "grey";
          }
          ctx.fillRect(i * cw, j * ch, cw, ch);
        }
      }
      for (int i= -12; i< 8 ; i++) {
         for (int j = 1; j< 3; j++) {
            q[nx ~/2 + i][ny - j] = 50.0;
          }
       }

       print('Temperature is ${(t[nx~/2][ny~/2])}');
       print('Temperature is ${(t[nx~/2][ny-1])}');
       print ('/');
}

/*  void thermostat() {

  double cutoff = t[nx~/2][ny~/2];

  for (int i= -12; i< 8 ; i++) {
     for (int j = 1; j< 3; j++) {
        q[nx ~/2 + i][ny - j] = (cutoff > 15.0) ? 0.0 : 100.0;
        //q[nx ~/2 + i][ny - j] = 200.0;

    }
  }
} */

void step(Timer timer) {
  for (int i=0; i<100; i++) {
    model.nextStep();

  }
  draw();
//  thermostat();

}
