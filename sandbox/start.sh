julia -t auto --project=. -e "using Revise; using DotEnv; using Pkg; Pkg.develop(path=\"..\"); using RMECf; DotEnv.load!();" -i
