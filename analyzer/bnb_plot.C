#include "ROOT/RDataFrame.hxx"
#include "TCanvas.h"
#include "TFile.h"
#include "TH1D.h"
#include "TH2D.h"

void bnb_plot(std::string inputFile="input.root", std::string outputFile="output.root"){
    TFile* f = TFile::Open(inputFile.c_str());
    if (!f || f->IsZombie()) {
      std::cerr << "Input file: " << inputFile << " not found!\n";
      return;
    } else {
      std::cout << inputFile << " successfully opened.\n";
    }
    TString treeName = f->GetListOfKeys()->At(0)->GetName();
    ROOT::RDataFrame df(treeName, inputFile);

    auto df_valid = df.Filter("daughterE > 0");

    auto df_numu = df_valid.Filter("daughterPDG == 14 && daughterPz > 0");
    auto df_numubar = df_valid.Filter("daughterPDG == -14 && daughterPz > 0");
    auto df_nue = df_valid.Filter("daughterPDG == 12 && daughterPz > 0");
    auto df_nuebar = df_valid.Filter("daughterPDG == -12 && daughterPz > 0");

    auto h_energy = df_valid.Histo1D(
        {"h_energy", "Neutrino Energy; Energy (GeV);Counts", 100, 0, 5},
        "daughterE"
    );
    auto h_profile = df_valid.Histo2D(
        {"h_profile", "Neutrino Profile at SBND(110 m); x []; y [m]", 100, -5, 5, 100, -5, 5},
        "x_ff_sbndCoord", "y_ff_beamCoord"
    );

    std::cout << "Generating Histograms ... \n";
    // x_ff_sbndCoord = x_ff_beamCoord + 0.74
    auto df_numu_ff = df_numu.Filter("x_ff_sbndCoord > -2.00 && x_ff_sbndCoord < 2.00 && y_ff_beamCoord > -2.00 && y_ff_beamCoord < 2.00");
    auto df_numubar_ff = df_numubar.Filter("x_ff_sbndCoord > -2.00 && x_ff_sbndCoord < 2.00 && y_ff_beamCoord > -2.00 && y_ff_beamCoord < 2.00");
    auto df_nue_ff = df_nue.Filter("x_ff_sbndCoord > -2.00 && x_ff_sbndCoord < 2.00 && y_ff_beamCoord > -2.00 && y_ff_beamCoord < 2.00");
    auto df_nuebar_ff = df_nuebar.Filter("x_ff_sbndCoord > -2.00 && x_ff_sbndCoord < 2.00 && y_ff_beamCoord > -2.00 && y_ff_beamCoord < 2.00");

    auto h_numu_ff_daughterE = df_numu_ff.Histo1D({"h_numu_ff_daughterE", "Numu daughterE after FF; daughterE; Events", 60, 0, 3},"daughterE");
    auto h_numubar_ff_daughterE = df_numubar_ff.Histo1D({"h_numubar_ff_daughterE", "Numubar daughterE after FF; daughterE; Events", 60, 0, 3},"daughterE");
    auto h_nue_ff_daughterE = df_nue_ff.Histo1D({"h_nue_ff_daughterE", "Nue daughterE after FF; daughterE; Events", 60, 0, 3},"daughterE");
    auto h_nuebar_ff_daughterE = df_nuebar_ff.Histo1D({"h_nuebar_ff_daughterE", "Nuebar daughterE after FF; daughterE; Events", 60, 0, 3},"daughterE");

    std::cout << "Producing SBN reference flux histogram ...\n";
    // 1. 히스토그램 정의: 이름, 제목, bin 개수(60), x축 시작(0.0), x축 끝(3.0)
    TH1F *hFlux = new TH1F("hFlux", "SBN Reference Flux;Neutrino Energy [GeV];#Phi(#nu_{#mu}) / 50MeV/m^{2}/10^{6}POT", 60, 0.0, 3.0);

    // 2. 판독 데이터 배열 (0.05 GeV 간격, 60개 값)
    float flux_data[] = {
        1.10, 3.80, 5.20, 6.50, 7.80, 8.80, 9.50, 10.20, 10.80, 11.20, // 0.00 - 0.45
        11.50, 11.50, 11.20, 10.80, 10.40, 9.80, 9.00, 8.20, 7.50, 6.80, // 0.50 - 0.95
        6.20, 5.50, 4.90, 4.30, 3.80, 3.40, 3.00, 2.60, 2.30, 2.05,     // 1.00 - 1.45
        1.80, 1.60, 1.40, 1.25, 1.10, 0.95, 0.82, 0.72, 0.62, 0.53,     // 1.50 - 1.95
        0.45, 0.40, 0.35, 0.31, 0.28, 0.25, 0.22, 0.20, 0.18, 0.16,     // 2.00 - 2.45
        0.15, 0.13, 0.12, 0.11, 0.10, 0.09, 0.085, 0.08, 0.075, 0.07    // 2.50 - 2.95
    };

    // 3. 히스토그램에 데이터 채우기
    for (int i = 0; i < 60; ++i) {
        // TH1 bin 인덱스는 1부터 시작합니다 (0은 underflow, 61은 overflow)
        hFlux->SetBinContent(i + 1, flux_data[i]);
    }

    // 4. 스타일 설정 및 그리기
    hFlux->SetLineColor(kRed);
    hFlux->SetLineWidth(2);

    // 5. 파일로 저장 (선택 사항)
    // TFile *outFile = new TFile("SBN_Flux.root", "RECREATE");
    // hFlux->Write();
    // outFile->Close();

    std::cout << "Writing output to the file " << outputFile << std::endl;
    TFile out(outputFile.c_str(), "RECREATE");
    h_energy->Write();
    h_profile->Write();

    h_numu_ff_daughterE->Write();
    h_numubar_ff_daughterE->Write();
    h_nue_ff_daughterE->Write();
    h_nuebar_ff_daughterE->Write();
    hFlux->Write();

    out.Close();

    std::cout << ">>> Analysis complete: " << outputFile << std::endl;
}
