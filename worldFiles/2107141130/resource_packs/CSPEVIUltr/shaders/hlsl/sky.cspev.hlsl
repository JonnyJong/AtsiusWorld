#include "ShaderConstants.fxh"

struct VS_Input
{
    float3 position : POSITION;
    float4 color : COLOR;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};


struct PS_Input
{
    float4 position : SV_Position;
    float4 color : COLOR;
    float3 w_pos : CSPE_w_pos;
#ifdef GEOMETRY_INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	uint renTarget_id : SV_RenderTargetArrayIndex;
#endif
};

ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput)
{
float3 pos = VSInput.position;
pos.y -=lerp(0.0,0.4,length(pos.xyz));
pos.y -=-0.11;

PSInput.w_pos=VSInput.position.xyz;

#ifdef INSTANCEDSTEREO
	int i = VSInput.instanceID;
	PSInput.position = mul( WORLDVIEWPROJ_STEREO[i], float4( pos, 1 ) );
#else
	PSInput.position = mul(WORLDVIEWPROJ, float4(pos, 1));
#endif
#ifdef GEOMETRY_INSTANCEDSTEREO
	PSInput.instanceID = VSInput.instanceID;
#endif 
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	PSInput.renTarget_id = VSInput.instanceID;
#endif
    PSInput.color = lerp( CURRENT_COLOR, FOG_COLOR, VSInput.color.r );

}