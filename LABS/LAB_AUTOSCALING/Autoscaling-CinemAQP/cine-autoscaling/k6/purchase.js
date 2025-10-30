import http from "k6/http";
import { sleep, check } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 10 },
    { duration: "4m", target: 25 },
    { duration: "2m", target: 0 },
  ],
};

const ALB = __ENV.ALB;

export default function () {
  // elige función aleatoria entre 1–8
  const fid = Math.ceil(Math.random() * 8);
  const url = `http://${ALB}/checkout/${fid}`;
  const payload = { cantidad: "1" };
  const params = { headers: { "Content-Type": "application/x-www-form-urlencoded" } };
  const res = http.post(url, payload, params);
  check(res, { "status redirect o 200": (r) => r.status === 200 || r.status === 302 });
  sleep(1);
}
