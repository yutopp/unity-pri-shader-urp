Shader "MyPriShader/Outline01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Outline)]
        _OutlineWidth("OutlineWidth", Range(0, 10)) = 0.0
        _OutlineColor("OutlineColor", Color) = (1,1,1,1)
        _OutlineTex("Outline (RGB)", 2D) = "black" {}
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Cull Front

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;

            uniform float _OutlineWidth;
            uniform float4 _OutlineColor;
            uniform sampler2D _OutlineTex;

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL; // OS = object space
                float2 texcoord0    : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv0          : TEXCOORD0;
            };

            Varyings vert(Attributes IN)
            {
                float4 positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                VertexNormalInputs n = GetVertexNormalInputs(IN.normalOS);
                // clip <- view <- world <- local
                // xyz: normal, w: viewDir.x で w を使っているよう
                // TransformObjectToHClip は w = 1.0 に決め打ちにするため、使うと壊れる
                float3 normalCS = mul(GetWorldToHClipMatrix(), n.normalWS);

                VertexPositionInputs p = GetVertexPositionInputs(IN.positionOS);

                // vert -> camera
                float3 vertToCameraDirWS = normalize(_WorldSpaceCameraPos - p.positionWS);

                // "法線"と"頂点からカメラ向き"の内積を取る。向きが同じであるほど1
                float NdotC = dot(normalize(n.normalWS), vertToCameraDirWS);
                // カメラと法線がずれるほど1。曖昧な角度のエッジを出さない補正
                float step = 1 - smoothstep(0.0, 1.0, NdotC);

                float4 outlineTexColor = tex2Dlod(_OutlineTex, float4(TRANSFORM_TEX(IN.texcoord0, _MainTex), 0, 0));
                // テクスチャの緑成分が太さの割合の減衰具合。緑が濃いほど線がなくなる
                float outlineRatio = 1.0f - outlineTexColor.g;

                // https://www.videopoetics.com/tutorials/pixel-perfect-outline-shaders-unity/
                float2 offset = (normalize(normalCS.xy) / _ScreenParams.xy) * _OutlineWidth * positionCS.w * 2;

                // OutLine
                Varyings OUT;

                OUT.positionHCS = positionCS;
                OUT.positionHCS.xy += offset * outlineRatio * step;

                OUT.uv0 = IN.texcoord0;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 mainTexColor = tex2D(_MainTex, TRANSFORM_TEX(IN.uv0, _MainTex));
                float4 mainColor = _OutlineColor * mainTexColor;

                return mainColor;
            }

            ENDHLSL
        }
    }
}
