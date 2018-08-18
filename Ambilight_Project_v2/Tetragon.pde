class Tetragon { 


  protected PVector tlCorner, trCorner, brCorner, blCorner;


  Tetragon (PVector c1, PVector c2, PVector c3, PVector c4) {  
    ArrayList<PVector> vector = new ArrayList<PVector>();
    int[] idx = new int[4];
    int tempIdx;

    idx[0] = 0;
    idx[1] = 1;
    idx[2] = 2;
    idx[3] = 3;

    vector.add(c1);
    vector.add(c2);
    vector.add(c3);
    vector.add(c4);

    //Sort vector by x ascend
    for (int i = 0; i < 3; i++) {
      for (int j = i; j < 4; j++) {
        if (vector.get(idx[j]).x < vector.get(idx[i]).x) {
          tempIdx = idx[j];
          idx[j] = idx[i];
          idx[i] = tempIdx;
        }
      }
    }

    //Sort the 2 left points
    if (vector.get(idx[0]).y < vector.get(idx[1]).y) {
      tlCorner = vector.get(idx[0]);
      blCorner = vector.get(idx[1]);
    } else {
      tlCorner = vector.get(idx[1]);
      blCorner = vector.get(idx[0]);
    }

    //Sort the 2 right points
    if (vector.get(idx[2]).y < vector.get(idx[3]).y) {
      trCorner = vector.get(idx[2]);
      brCorner = vector.get(idx[3]);
    } else {
      trCorner = vector.get(idx[3]);
      brCorner = vector.get(idx[2]);
    }
  } 


  PVector getCorner(String pos) {
    switch(pos) {
    case "tl": 
      return tlCorner;
    case "tr": 
      return trCorner;
    case "br": 
      return brCorner;
    case "bl": 
      return blCorner;
    }
    return null;
  }


  ArrayList<Tetragon> subdivide(int n) {
    ArrayList<Tetragon> result = new ArrayList<Tetragon>();
    ArrayList<Tetragon> temp = new ArrayList<Tetragon>();
    Line vll, vml, vrl, htl, hml, hbl, diag1, diag2;
    PVector topP, rightP, leftP, botP, midP, vertEscapeP, horEscapeP;

    vll = new Line();
    vll.fitTwoPoints(tlCorner, blCorner);

    vrl = new Line();
    vrl.fitTwoPoints(trCorner, brCorner);

    htl = new Line();
    htl.fitTwoPoints(tlCorner, trCorner);

    hbl = new Line();
    hbl.fitTwoPoints(blCorner, brCorner);

    diag1 = new Line();
    diag1.fitTwoPoints(tlCorner, brCorner);

    diag2 = new Line();
    diag2.fitTwoPoints(trCorner, blCorner);


    midP = diag1.intersectionWith(diag2);
    vertEscapeP = vll.intersectionWith(vrl);
    horEscapeP = htl.intersectionWith(hbl);

    if (vertEscapeP == null) { //If no intersection, lines are parallels
      if (vrl.type == lineType.VERT) {
        vml = new Line(midP.x);
      } else {
        vml = new Line(vrl.getSlope(), midP.y - vrl.getSlope() * midP.x);
      }
    } else {
      vml = new Line();
      vml.fitTwoPoints(vertEscapeP, midP);
    }

    if (horEscapeP == null) { //If no intersection, lines are parallels
      hml = new Line(htl.getSlope(), midP.y - htl.getSlope() * midP.x);
    } else {
      hml = new Line();
      hml.fitTwoPoints(horEscapeP, midP);
    }

    ////Draw the lines
    //line(tlCorner.x, tlCorner.y, blCorner.x, blCorner.y);
    //line(trCorner.x, trCorner.y, brCorner.x, brCorner.y);
    //line(tlCorner.x, tlCorner.y, trCorner.x, trCorner.y);
    //line(blCorner.x, blCorner.y, brCorner.x, brCorner.y);
    //line(0, vml.getOrigin(), 500, vml.getSlope()*500+vml.getOrigin());
    //line(0, hml.getOrigin(), 500, hml.getSlope()*500+hml.getOrigin());

    topP = htl.intersectionWith(vml);
    rightP = vrl.intersectionWith(hml);
    leftP = vll.intersectionWith(hml);
    botP = hbl.intersectionWith(vml);

    temp.add(new Tetragon(tlCorner, topP, midP, leftP));
    temp.add(new Tetragon(topP, trCorner, rightP, midP));
    temp.add(new Tetragon(midP, rightP, brCorner, botP));
    temp.add(new Tetragon(leftP, midP, botP, blCorner));

    if (n > 1) {
      for (int i = 0; i < 4; i++) {
        result.addAll(temp.get(i).subdivide(n-1));
      }
    } else {
      result = temp; 
    }

    return result;
  }


  void infos() {
    println("Top left corner     : (" + tlCorner.x + "," + tlCorner.y + ")");
    println("Top right corner    : (" + trCorner.x + "," + trCorner.y + ")");
    println("Bottom right corner : (" + brCorner.x + "," + brCorner.y + ")");
    println("Bottom left corner  : (" + blCorner.x + "," + blCorner.y + ")");
  }

  void display() {
    noStroke();
    fill(0, 0, 255);
    ellipse(tlCorner.x, tlCorner.y, 4, 4);
    ellipse(trCorner.x, trCorner.y, 4, 4);
    ellipse(brCorner.x, brCorner.y, 4, 4);
    ellipse(blCorner.x, blCorner.y, 4, 4);
  }
  
  void display(float dx, float dy, float horFactor, float vertFactor) {
    noStroke();
    fill(0, 0, 255);
    
    ellipse(horFactor * tlCorner.x + dx, vertFactor * tlCorner.y + dy, 4, 4);
    ellipse(horFactor * trCorner.x + dx, vertFactor * trCorner.y + dy, 4, 4);
    ellipse(horFactor * brCorner.x + dx, vertFactor * brCorner.y + dy, 4, 4);
    ellipse(horFactor * blCorner.x + dx, vertFactor * blCorner.y + dy, 4, 4);
  }
} 
