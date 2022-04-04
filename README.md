# okctl v2

## Løsningsforslag

* Alternativ 1: Implementere alternativ 2 inn i Okctl.
  * På sikt fase ut apply / delete cluster (for EKS).
* Alternativ 2: Lage nytt CLI (`ok`?) som produserer Terraform / Pulumi hvor brukeren selv kjører `tf apply` / `pl up`.
  * På sikt fase ut Okctl.

## Prinsipper / Tanker for et CLI-verktøy

- Hjelpescripts i hverdagen er en nødvendighet, og noe vi ønsker å beholde fra Okctl.
    - Selv lager jeg hjelpescripts hele tiden i min utviklerhverdag for å forbedre DX/UX. Som applikasjonsutvikler ville jeg
      ønsket at noen (mao. Kjøremiljø) kunne lagd disse.
- Å ha ett CLI som Okctl er en god ide. Man kunne i prinsippet hatt et GitHub-repository som alle utviklere putta i PATH-en sin
  (på ITAS Classic gjorde man dette), men det er enklere å oppdatere et CLI (med installasjonscript, okm, brew/apt) enn at alle
  skal kjøre git pull hele tiden.
- Okctl skal spille på lag med eksisterende verktøy som finnes der ute (aws cli, terraform, pulumi, alskens verktøy fra 
  internett). Okctl skal ikke være en hindring, eller være et begrensende abstraksjonslag. Okctl skal likevel kunne gjøre
  opplevelsen og sammensyingen av disse verktøyene bedre. Hvis Okctl tryner, skal det fortsatt være mulig å gjøre ting manuelt.
    - Eksempel: Vi skal ikke måtte lage støtte for SSO før brukere kan ta det i bruk, det skal være mulig å bruke eksisterende
      verktøy. Når det er sagt, kan vi godt likevel lage en smoothere UX-løsning for å logge inn.
- Som applikasjonsutvikler ønsker jeg at Kjøremiljø hjelper meg med å bruke verktøy som finnes der ute. Samtidig vil jeg ikke
  at noen skjuler essensielle ting for meg, om det er Kubernetes manifester, Terraform eller Pulumi. Dette er ting man blir
  nødt å forstå uansett når problemer oppstår.
- Go kan være overkill og slitsomt for enkle scripts, det hadde vært fint om vi kunne bruke Bash der det ga mening, og Go for alt
  utover det.

## Implementasjon alternativ 1

* Dagens EKS-spesifikke kommandoer flyttes til `okctl eks`, så f.eks `okctl eks apply cluster`
* Ikke nødvendig, men foreslår en mer feature basert oppdeling av kommandoer, slik som `aws` CLI-et gjør det (`aws s3 ls`). Eks:
  `okctl ecs scaffold cluster` framfor `okctl scaffold ecs cluster`. `okctl upgrade` gir feks ikke mening for lambda (ok, kanskje,
  men poenget er at ikke alle actions passer til alle ressurser), så derfor burde det være
  `okctl eks upgrade`.

### Kommandoer

```shell
# Logge inn til miljø, alternativ 1:
. okctl sso login # Se forslag til implementasjon i Appendix lengre ned

# Logge inn til miljø, alternativ 2:
. okctl venv -c env-dev.yaml # 
. okctl venv -c env-dev.yaml --terminal fish

okctl ecs scaffold cluster
okctl ecs scaffold service
okctl lambda scaffold

# Eksisterende EKS-spesifikke kommandoer flyttes til okctl eks:
okctl eks apply cluster ...
okctl eks delete cluster ...

okctl eks apply application ...
okctl eks upgrade
okctl eks forward

# Eksisterende generelle kommandoer beholdes
okctl completion
okctl version
```

* `okctl venv` kan beholdes, men skrives om til å bruke `source okctl venv`, se forslag i https://trello.com/c/MMGaZQZa/532-okctl-venv-sets-wrong-awsprofile.

### Detaljer

```shell
$ okctl ecs scaffold cluster

Gennerating Pulumi...

Fire up your new component by running:

cd remote_state
pl preview
pl up

cd ecs
pl preview
pl up
```
    
Kommandoen laster ned github.com/oslokommune/okctl/pulumi/ecs/cluster, som er -bruk- av en ecs komponent (tilsvarer TF modul),
ikke selve komponenten. I Pulumi gjør man det med package.json, i Terraform bruker referer man til en modul med versjon i GitHub.

## Implementasjon alternativ 2

Nytt verktøy, feks `ok`.

```shell
. ok sso login
# eller
. ok venv -c env-dev.yaml

ok ecs scaffold cluster
ok ecs scaffold service
ok lambda scaffold

ok completion
ok version
```

# Appendix

## Forbedre UX for `aws sso login`

Putter dette her for å beskrive hvordan man forholdsvis enkelt kunne forbedret UX for login med AWS SSO.

Manuelt:

```sh
$ aws sso login
Missing the following required SSO configuration values: sso_start_url, sso_region, sso_role_name, sso_account_id. To make sure this profile is properly configured to use SSO, please run: aws configure sso

# Bruker skjønner nada. Finner til slutt ut av hva som må gjøres.

$ aws configure sso

...

$ export AWS_PROFILE=AWSAdministratorAccess-123456789012 # Gørr å skrive denne for hver nye terminal, hver dag

$ aws sso login

...

$ aws s3 ls

2021-01-06 11:20:26 my-bucket
```

Med hjelpescript: [okctl-sso-login.sh](okctl-sso-login.sh)
* Kan gjøres greit i Bash (enn så lenge), trenger ikke Go.
    * Tanken er at `okctl` bare kaller Bash-scriptet og forwarder argumenter.
* Setter opp miljøvariabel, så brukeren slipper å kjøre `export AWS_PROFILE=...`

Tenkt bruksmønster (PS: [okctl-sso-login.sh](okctl-sso-login.sh) gjør ikke nøyaktig det som skjer under, litt annen tekst bl.a.):

```sh
$ . okctl sso login
```

Bruker får opp en dropdown liste, hvor hen velger miljøet en ønsker å logge inn i:

![](/sso-login-fzf.png)

```sh
$ . okctl sso login

>
  3/3
  default
  AWSAdministratorAccess-321564987123
  AWSAdministratorAccess-123456789012

# Brukeren velger konto i drop down over (bruker verktøyet fzf)

You are now logged in with AWS_PROFILE=AWSAdministratorAccess-123456789012
Test it out with: aws s3 ls

$ aws s3 ls

2021-01-06 11:20:26 my-bucket

$ echo $AWS_PROFILE # Denne blir automatisk satt
AWSAdministratorAccess-123456789012
```

Man kan også utvide scriptet med å detektere at `aws configure sso` ikke er kjørt, og kjøre dette for brukeren eller guide hen igjennom det.

