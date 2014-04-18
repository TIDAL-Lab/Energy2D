library Energy2D;

import 'dart:html';
import 'dart:math';

part 'matrix.dart';

var context;

Matrix cells;


void main() {
  print("hello");
  double energy = PI * 4;
  
  print("the value of energy is ${energy / 2}");
  
  
  cells = new Matrix(20, 20);
  cells.randomize(0.0, 255.0);
  
  CanvasElement canvas = querySelector("#world");
  
  context = canvas.getContext("2d");

  draw();
}



void draw() {
  
  int red = 0;
  int green = 0;
  int blue = 100;
  
  for (int i=0; i<20; i++) {
    for (int j=0; j<20; j++) {
      red = i * 10;
      green = j * 10;
      
      //context.fillStyle = "rgb(${red}, ${green}, ${blue})";
      
      context.fillStyle = "rgb(0, ${cells.getValue(i,j).toInt()}, 0)";
      
      context.fillRect(i*30, j*30, 30, 30);
    }
  }
}