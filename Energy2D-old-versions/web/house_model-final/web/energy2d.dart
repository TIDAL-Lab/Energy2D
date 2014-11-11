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

CanvasRenderingContext2D ctx2;

Model2D model;

int width = 600;
int height = 400;
bool running = false;
Timer timer = null;

Matrix<double> t;
Matrix<double> conductivity;
Matrix<double> q;
int nx;
int ny;
double cw;
double ch;
double t0;

void main() {

  model = new Model2D(70,70);

  t = model.t;
  q = model.q;
  nx = model.nx;
  ny = model.ny;
  cw = width / model.nx;
  ch = height / model.ny;

 CanvasElement canvas = querySelector("#layer3");
  width = canvas.width;
  height = canvas.height;
  ctx2 = canvas.getContext('2d');
  canvas.onClick.listen(startStop);

}


void animation (double i) {
  window.animationFrame.then(animation);
  draw2();
}

void startStop(MouseEvent event) {
  window.animationFrame.then(animation);
}

void draw2() {
 if (!model.valid){
 // ctx2.clearRect(0, 0, width, height);

  int r, h;
  double cutoff = t[nx~/2][ny~/2];

    for (int i=0; i<t.cols; i++) {
     for (int j=0; j<t.rows; j++) {
         double temp = t[i][j];

         if (model.fluidity[i][j]) {

            h = ((0.1206 * temp * temp)-(12.498 * temp)+257.71).round();
            if(t[i][j]<28.0){

              ctx2.fillStyle = 'hsl($h, 80%, 50%)';
            }
            else {
                  ctx2.fillStyle = 'hsl(0, 80%, 50%)';
                     }
            if (t[i][j]<0.0){
              ctx2.fillStyle = "white";
            }
         }
            else {
               ctx2.fillStyle = "grey";
            }
            ctx2.fillRect(i * cw, j * ch, cw+0.5, ch+0.5);
        }
      }

    for (int i= 35; i<45; i++) {
     for (int j = ny-7; j< ny-4; j++) {
        q[i][j] = 3500.0;
      }
    }

    model.valid = true;
    }
      model.nextStep();
    }


void step(Timer timer) {
  for (int i=0; i<20; i++) {
    model.nextStep();
  }
  //model.nextStep();
  draw2();

}


