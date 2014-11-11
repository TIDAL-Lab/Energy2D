library Energy2D;

import 'dart:async';
import 'dart:html';
import 'dart:math';

part 'fluidsolver.dart';
part 'heatsolver.dart';
part 'massboundary.dart';
part 'mathutil.dart';
part 'matrix.dart';
part 'model.dart';
part 'part.dart';
part 'thermalboundary.dart';


/*
 * By default, air's kinematic viscosity = 1.568 x 10^-5 m^2/s at 27 C is
 * used. It can be set to zero for inviscid fluid.
 */


double ch;

Matrix<double> conductivity;

CanvasRenderingContext2D ctx3, ctx2;
double cw;
int height = 400;
Model2D model;

int nx;
int ny;
Matrix<double> q;
bool running = false;
Matrix<double> t;
double t0;
Timer timer = null;
int width = 600;


void animation(double i) {
  window.animationFrame.then(animation);
  draw2();
  draw3();
}

void draw2() {

  double temp = t[50][25];
  double tempF = (temp * 1.8) + 32.0; // converts double to string with upto 4 significan digits
  var disT = tempF.toStringAsFixed(0);

  ctx2.clearRect(0, 0, width, height);
  // window accents
  ctx2.fillStyle = "#5C5C5C";
  ctx2.fillRect(154, 183, 9, 9);
  ctx2.fillRect(154, 314, 9, 9);
  ctx2.fillRect(161, 183, 19, 140);

// power status of thermostat
  for (int i = 35; i < 45; i++) {
    for (int j = ny - 7; j < ny - 4; j++) {
      if (q[i][j] > 0.0) {

        ctx2.fillStyle = "black";
        ctx2.fillRect(255, 358, 132, 19);
        ctx2.fillStyle = "white";
        ctx2.font = "20px Times";
        ctx2.fillText("ON", 310, 375);

      } else {
        ctx2.fillStyle = "white";
        ctx2.fillRect(255, 358, 132, 19);
        ctx2.fillStyle = "black";
        ctx2.font = "20px Times";
        ctx2.fillText("OFF", 300, 375);

        }
    }
  }

// Temp display
  ctx2.beginPath();
  ctx2.arc(430, 150, 20, 0, 2 * PI, false);
  ctx2.fillStyle = "blue";
  ctx2.fill();
  ctx2.lineWidth = 9;
  ctx2.strokeStyle = '#003300';
  ctx2.stroke();
  ctx2.fillStyle = "white";
  ctx2.font = "18px Palatino";
  ctx2.fillText("$disT", 421, 156);
}

void draw3() {
  if (!model.valid) {
 ctx3.clearRect(0, 0, width, height);
    int r, h;
    double cutoff = t[50][25];

    for (int i = 0; i < t.cols; i++) {
      for (int j = 0; j < t.rows; j++) {
        double temp = t[i][j];

        if (model.fluidity[i][j]) {

          h = ((0.0118 * temp * temp* temp) - (0.3988 * temp * temp) - (6.9989 * temp) + 251.9).round();
          if (t[i][j] < 28.0) {

            ctx3.fillStyle = 'hsl($h, 80%, 50%)';
          } else {
            ctx3.fillStyle = 'hsl(0, 80%, 50%)';
          }
          if (t[i][j] < 0.0) {
            ctx3.fillStyle = "white";
          }
        } else {
          ctx3.fillStyle = "grey";
        }
        ctx3.fillRect(i * cw, j * ch, cw + 1.5, ch + 1.5);
      }
    }

    for (int i = 35; i < 45; i++) {
      for (int j = ny - 7; j < ny - 4; j++) {
        //  q[i][j] = 3500.0;
        q[i][j] = (cutoff > 15.0) ? 0.0 : 2500.0;
      }
    }
    print('temperature is $cutoff');
    model.valid = true;
  }
  model.nextStep();
}

void main() {

  model = new Model2D(70, 70);

  t = model.t;
  q = model.q;
  nx = model.nx;
  ny = model.ny;
  cw = width / model.nx;
  ch = height / model.ny;

  CanvasElement canvas = querySelector("#layer3");
  width = canvas.width;
  height = canvas.height;
  ctx3 = canvas.getContext('2d');

  CanvasElement canvas1 = querySelector("#layer2");
  width = canvas1.width;
  height = canvas1.height;
  ctx2 = canvas1.getContext('2d');
  canvas.onClick.listen(startStop);
  canvas1.onClick.listen(startStop);

}

void startStop(MouseEvent event) {
  window.animationFrame.then(animation);
}



void step(Timer timer) {
  for (int i = 0; i < 20; i++) {
    model.nextStep();
  }

  draw2();
  draw3();

}

