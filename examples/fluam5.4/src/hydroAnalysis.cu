// Filename: hydroAnalysis.cu
//
// Copyright (c) 2010-2013, Florencio Balboa Usabiaga
//
// This file is part of Fluam
//
// Fluam is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Fluam is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Fluam. If not, see <http://www.gnu.org/licenses/>.


#define GLOBALS_HYDROANALYSIS 1

#include "header.h"
#include "cells.h"
#include "fluid.h"
#include "headerOtherFluidVariables.h"
//Includes from TestHydroGrid.c
extern "C" {
#include "HydroGrid.h"
}
//#include "RNGs.h"
#define NDIMS 3
#include "hydroAnalysis.h"

bool hydroAnalysis(int counter){
  //int nCells[3];
  //double systemLength[3];
  //double heatCapacity[1];
  //double standardDesviation; // Standard deviation
  //double *velocities;
  //double *densities;
  //double *concent;



  if(counter == 0){
    ifstream fileinput;
    fileinput.open("hydroGridOptions.nml");
    string word, wordfile;
    while(!fileinput.eof()){
      getline(fileinput,word);
      wordfile += word + "\n";
    }
    fileinput.close();
    string fileOutName;
    fileOutName = outputname + ".hydroGridOptions.nml";
    ofstream fileout(fileOutName.c_str());
    fileout << wordfile << endl;
    fileout.close();

    //
    nCells[0] = mx;
    nCells[1] = my;
    nCells[2] = mz;
    systemLength[0] = lx;
    systemLength[1] = ly;
    systemLength[2] = lz;
    heatCapacity[0] = 1.;
    velocities = new double [NDIMS*mx*my*mz];
    densities = new double [mx*my*mz];
    //concent = new double [mx*my*mz];
    if(temperature==0){
      createHydroAnalysis_C(nCells,1,NDIMS,1,systemLength,heatCapacity,dt*samplefreq,0,1,0);
    }
    else{
      createHydroAnalysis_C(nCells,1,NDIMS,1,systemLength,heatCapacity,dt*samplefreq,0,densfluid/temperature,0);
    }
  }
  else if(counter == 1){
    for(int i=0;i<ncells;i++) {
      velocities[i] = cvx[i];
      velocities[i+ncells] = cvy[i];
      velocities[i+2*ncells] = cvz[i];
      densities[i] = cDensity[i];
    }
    updateHydroAnalysisIsothermal_C(velocities, densities);
    //updateHydroAnalysisMixture_C (velocities, densities, concent);
  }
  else if(counter == 2){
    writeToFiles_C(-1); // Write to files
    destroyHydroAnalysis_C();
    delete[] velocities;
    delete[] densities;
    //delete[] concent;
  }
  else if(counter == 3){
    if(step==0){
      writeToFiles_C(0); // Write to files
    }
    else{
      writeToFiles_C(step/savefreq); // Write to files
    }
  }
  return 1;
}



