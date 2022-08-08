--Projeto de Principios de Programacao 2018/2019
--Ana Albuquerque, nº 53512
--Diogo Lopes, nº 51058

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

import System.IO
import System.Environment
import Data.List
import Test.QuickCheck
import System.Random

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

type Pixel = (Int, Int, Int)

type FuncaoDeTransf = [[Pixel]] -> [[Pixel]] --FuncaoDeTransf significa FuncaoDeTransformacao

--Criacao do tipo de dados PPM que recebe:
--a largura (l) e altura (a) da imagem em pixeis;
--o valor maximo (m) para cada cor;
--uma matriz de pixeis (p).
data PPM = PPM { l :: Int
               , a :: Int
               , m :: Int
               , p :: [[Pixel]]
               }

ppm :: Int -> Int -> Int -> [[Pixel]] -> PPM
ppm larg alt max pix = PPM { l = larg
                           , a = alt
                           , m = max
                           , p = pix
                           }

instance Show PPM where
    show PPM {l = larg, a = alt, m = max, p = pix} = 
        "P3\n" ++ show larg ++ " " ++ show alt ++ " "
        ++ show max ++ " " ++ matrizParaString pix
        where matrizParaString = aplicador linhasParaString
              linhasParaString =  aplicador pixelParaString
              pixelParaString (r, g, b) = show r ++ " " ++ show g ++ " " ++ show b
              aplicador funcao = unwords . (map funcao) --funcao auxiliar

instance Arbitrary PPM where
    arbitrary = do
      larg <- choose (1,300)
      alt <- choose (1,300)
      max <- choose (0,255)
      let numCoresPixel = 3
      numeros <- vectorOf (larg * alt * numCoresPixel) (choose (0, max))
      let pixAgrupadosPorLinha = agrupaLista larg listaPixeis
          listaPixeis = agrupaEmTriplos numeros
      return $ PPM larg alt max pixAgrupadosPorLinha

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

listaAssoc :: [ ( String, FuncaoDeTransf ) ]
listaAssoc = [ ("-fh", flipHorizontal)
             , ("-fv", flipVertical)
             , ("-hw", metadeDaLargura)
             , ("-hh", metadeDaAltura)
             , ("-gs", escalaDeCinzentos)
             , ("-rc", vermelhosApenas)
             , ("-gc", verdesApenas)
             , ("-bc", azuisApenas)]

main = do
    (argumento:_) <- getArgs
    if (argumento == "-t")
        then do
             quickCheck prop_flipHorizontal
             quickCheck prop_PPM
             quickCheck prop_maximo
             quickCheck prop_reduz              
        else do
            (input:output:flags) <- getArgs
            contents <- readFile input
            let ficheiroPPM = converteParaPPM contents
                largAposTransf = getLargFin pixeisAposTransf
                altAposTransf = getAltFin pixeisAposTransf
                pixeisAposTransf = executaSeqFuncoes flags (p ficheiroPPM)
                novoFicheiroPPM = ppm largAposTransf altAposTransf (m ficheiroPPM) pixeisAposTransf
            writeFile output $ show novoFicheiroPPM


--Converte a informacao do ficheiro para o tipo de dados PPM
converteParaPPM :: String -> PPM
converteParaPPM contents = ppm larg alt max pixAgrupadoPorLinha
    where larg = getLargura nums
          alt = getAltura nums
          max = getMaximo nums
          pixAgrupadoPorLinha = agrupaLista larg listaPixeis 
          listaPixeis = agrupaEmTriplos coresPixeis 
          coresPixeis = sohPixeis nums
          nums = numsDoFicheiro contents

--Faz as transformacoes sobre os pixeis uma a uma
executaSeqFuncoes :: [String] -> [[Pixel]] -> [[Pixel]]
executaSeqFuncoes flags pixeis = foldl (\acc func -> func acc) pixeis listaFunc
    where listaFunc = obtemFuncoes flags

--Dada uma lista com flags, traduz essas flags para as funcoes correspondentes na listaAssoc
obtemFuncoes :: [String] -> [FuncaoDeTransf]
obtemFuncoes flags = map apenasFuncao $ filter tiraNothing $ flagsParaMaybeFunc 
    where flagsParaMaybeFunc = map (flip lookup listaAssoc) flags
          tiraNothing (Just _) = True
          tiraNothing Nothing = False
          apenasFuncao (Just funcao) = funcao

--Converte a string do ficheiro original numa lista de inteiros
numsDoFicheiro :: String -> [Int]
numsDoFicheiro texto =  map read stringsRelevantes :: [Int]
    where stringsRelevantes = words textoLimpo
          textoLimpo = unlines linhasRelevantes
          linhasRelevantes = limpaComentarios $ limpaLinhasEmBranco linhasTodas
          linhasTodas = lines texto

limpaComentarios :: [String] -> [String]
limpaComentarios = tail . filter (\(char1:_) -> (char1 /= '#')) -- tail eh usado para descartar a primeira linha que tem a String "P3"

limpaLinhasEmBranco :: [String] -> [String]
limpaLinhasEmBranco = filter (\linha -> (linha /= []))

getLargura :: [Int] -> Int
getLargura = head

getAltura :: [Int] -> Int
getAltura = head . tail

getLargFin :: [[Pixel]] -> Int 
getLargFin = length . head -- como todas as linhas tem o mesmo comprimento so precisamos de saber o de uma delas

getAltFin :: [[Pixel]] -> Int
getAltFin = length

getMaximo :: [Int] -> Int
getMaximo = head . tail . tail

sohPixeis :: [Int] -> [Int]
sohPixeis = drop 3 -- descarta-se a largura, a altura e o maximo

agrupaLista :: Int -> [Pixel] -> [[Pixel]]
agrupaLista _ [] = []
agrupaLista fator lista = take fator lista : agrupaLista fator restoDaLista 
    where restoDaLista = (drop fator lista)

agrupaEmTriplos :: [Int] -> [Pixel]
agrupaEmTriplos [] = []
agrupaEmTriplos (a:b:c:resto) = (a, b, c) : agrupaEmTriplos resto

flipHorizontal :: FuncaoDeTransf
flipHorizontal = map reverse -- inverte-se cada linha

flipVertical :: FuncaoDeTransf
flipVertical = reverse -- inverte-se a ordem das linhas

mediaN :: [Int] -> Int
mediaN numeros = (sum numeros) `div` (length numeros) 

--Faz a media dos pixeis de uma linha dois a dois 
--Se a linha tiver um numero impar de pixeis, descarta o ultimo
metadeDaLinha :: [Pixel] -> [Pixel]
metadeDaLinha [] = []
metadeDaLinha (pixN:[]) = []
metadeDaLinha (pix1:pix2:restoPixeis) = media2Pixeis : metadeDaLinha restoPixeis 
    where media2Pixeis = mediaPixeis pix1 pix2 
          mediaPixeis (r1, g1, b1) (r2, g2, b2) = (mediaN [r1, r2], mediaN [g1, g2], mediaN [b1, b2])

metadeDaLargura :: FuncaoDeTransf
metadeDaLargura = map metadeDaLinha

metadeDaAltura :: FuncaoDeTransf
metadeDaAltura = transpose . metadeDaLargura . transpose

escalaDeCinzentos :: FuncaoDeTransf
escalaDeCinzentos = map $ map media1P
    where media1P (a, b, c) = (mediaN [a, b, c], mediaN [a, b, c], mediaN [a, b, c])       

atualizaCor :: Int -> Pixel -> Pixel
atualizaCor i (r, g, b)
            | i == 0 = (r,0,0)
            | i == 1 = (0,g,0)
            | i == 2 = (0,0,b)

vermelhosApenas :: FuncaoDeTransf
vermelhosApenas = map $ map $ atualizaCor 0

verdesApenas :: FuncaoDeTransf
verdesApenas = map $ map $ atualizaCor 1

azuisApenas :: FuncaoDeTransf
azuisApenas = map $ map $ atualizaCor 2


-------------------------------------------------------------------------QuickCheck------------------------------------------------------------------------------------------

--Uma imagem invertida horizontalmente duas vezes é a imagem original.
prop_flipHorizontal :: [[Pixel]] -> Bool
prop_flipHorizontal pixeis = flipHorizontal (flipHorizontal pixeis) == pixeis


--Qualquer imagem tem um número de pixeis igual ao produto das dimensões no cabeçalho da imagem.
prop_PPM :: PPM -> Bool
prop_PPM ppm = sum (map length (p ppm)) == (l ppm) * (a ppm)


--Nenhum dos valores dos pixeis são superiores ao valor máximo apresentado no cabeçalho.
prop_maximo :: PPM -> Bool
prop_maximo ppm = verificaMatriz (p ppm)
    where verificaMatriz = aplicador verificaLinhasM
          verificaLinhasM = aplicador verificaPixLM
          verificaPixLM = triploSatisfaz condicao
          condicao = (<= max)
          aplicador funcao = and . (map funcao) --funcao auxiliar
          max = (m ppm)

triploSatisfaz :: (a -> Bool) -> (a, a, a) -> Bool
triploSatisfaz pred (a1, a2, a3) = pred a1 && pred a2 && pred a3


--Uma operação de redução de largura seguida de uma de redução de altura mantem o rácio largura/altura inalterado.
prop_reduz :: PPM -> Property
prop_reduz ppm = largAltPares ==> largFin `div` altFin == largOrig `div` altOrig
    where largAltPares = even largOrig && even altOrig
          largFin = (getLargFin ppmReduzido)
          altFin = (getAltFin ppmReduzido)
          largOrig = (l ppm)
          altOrig = (a ppm)
          ppmReduzido = metadeDaAltura (metadeDaLargura (p ppm))


